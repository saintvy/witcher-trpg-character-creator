import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as apigw from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigwIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as apigwAuthorizers from 'aws-cdk-lib/aws-apigatewayv2-authorizers';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';
import * as path from 'path';

export class WccStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Global cost/accounting tag for all taggable resources in this stack.
    cdk.Tags.of(this).add('witcher-cc', 'true');

    const appName = 'wcc';
    const cognitoJwtIssuer = process.env.WCC_COGNITO_JWT_ISSUER?.trim();
    const cognitoJwtAudience = (process.env.WCC_COGNITO_JWT_AUDIENCE ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
    const apiAuthModeOverride = process.env.WCC_API_AUTH_MODE?.trim() ?? 'none';

    // ================================================================
    // 1. NETWORK (VPC)
    // ================================================================
    // Cost-optimized VPC for Lambda + RDS. NAT is disabled on purpose:
    // Lambda uses VPC endpoints to reach required AWS APIs privately.
    const vpc = new ec2.Vpc(this, 'WccVpc', {
      maxAzs: 2,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: 'app-isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          cidrMask: 24,
        },
      ],
    });

    const lambdaSecurityGroup = new ec2.SecurityGroup(
      this,
      'WccApiLambdaSecurityGroup',
      {
        vpc,
        description: 'Security group for API Lambda inside isolated subnets',
        allowAllOutbound: false,
      },
    );

    const dbSecurityGroup = new ec2.SecurityGroup(this, 'WccDbSecurityGroup', {
      vpc,
      description: 'PostgreSQL ingress only from API Lambda',
      allowAllOutbound: false,
    });

    dbSecurityGroup.addIngressRule(
      lambdaSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow PostgreSQL from API Lambda',
    );

    const secretsManagerEndpointSecurityGroup = new ec2.SecurityGroup(
      this,
      'WccSecretsManagerEndpointSecurityGroup',
      {
        vpc,
        description: 'Allow HTTPS from API Lambda to Secrets Manager VPC endpoint',
        allowAllOutbound: true,
      },
    );

    secretsManagerEndpointSecurityGroup.addIngressRule(
      lambdaSecurityGroup,
      ec2.Port.tcp(443),
      'Allow Lambda to use Secrets Manager interface endpoint',
    );

    lambdaSecurityGroup.addEgressRule(
      dbSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow Lambda to connect to PostgreSQL',
    );

    lambdaSecurityGroup.addEgressRule(
      secretsManagerEndpointSecurityGroup,
      ec2.Port.tcp(443),
      'Allow Lambda to call Secrets Manager through VPCE',
    );

    // DNS queries for private hostname resolution inside the VPC
    // (RDS endpoint + Secrets Manager private DNS).
    lambdaSecurityGroup.addEgressRule(
      ec2.Peer.ipv4(vpc.vpcCidrBlock),
      ec2.Port.udp(53),
      'Allow DNS (UDP) inside VPC',
    );
    lambdaSecurityGroup.addEgressRule(
      ec2.Peer.ipv4(vpc.vpcCidrBlock),
      ec2.Port.tcp(53),
      'Allow DNS (TCP) inside VPC',
    );

    const secretsManagerVpcEndpoint = new ec2.InterfaceVpcEndpoint(
      this,
      'WccSecretsManagerVpcEndpoint',
      {
        vpc,
        service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
        privateDnsEnabled: true,
        subnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
        securityGroups: [secretsManagerEndpointSecurityGroup],
      },
    );

    // ================================================================
    // 2. DATABASE (RDS PostgreSQL)
    // ================================================================
    const database = new rds.DatabaseInstance(this, 'WccDb', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        ec2.InstanceSize.MICRO,
      ),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      securityGroups: [dbSecurityGroup],
      publiclyAccessible: false,
      databaseName: 'witcher_cc',
      credentials: rds.Credentials.fromGeneratedSecret('cc_user'),
      multiAz: false,
      allocatedStorage: 20,
      storageType: rds.StorageType.GP3,
      maxAllocatedStorage: 50,
      backupRetention: cdk.Duration.days(1),
      deleteAutomatedBackups: true,
      autoMinorVersionUpgrade: true,
      deletionProtection: false,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
    });

    // ================================================================
    // 3. LAMBDA (API)
    // ================================================================
    // NodejsFunction bundles cloud/api + workspace dependencies (including @wcc/core)
    // into a single deployable Lambda asset.
    const apiFunction = new lambdaNodejs.NodejsFunction(this, 'WccApiFunction', {
      runtime: lambda.Runtime.NODEJS_20_X,
      entry: path.join(__dirname, '../../api/src/lambda.ts'),
      handler: 'handler',
      depsLockFilePath: path.join(__dirname, '../../../package-lock.json'),
      projectRoot: path.join(__dirname, '../../..'),
      bundling: {
        sourceMap: true,
        target: 'node20',
        format: lambdaNodejs.OutputFormat.CJS,
        commandHooks: {
          beforeBundling() {
            return [];
          },
          beforeInstall() {
            return [];
          },
          afterBundling(inputDir, outputDir) {
            return [
              `node -e "const fs=require('fs'); const path=require('path'); const [inDir,outDir]=process.argv.slice(1); const src=path.join(inDir,'packages','core','src','data','defaultCharacter.json'); const dst=path.join(outDir,'defaultCharacter.json'); fs.copyFileSync(src,dst);" "${inputDir}" "${outputDir}"`,
            ];
          },
        },
      },
      memorySize: 256,
      timeout: cdk.Duration.seconds(29),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      securityGroups: [lambdaSecurityGroup],
      environment: {
        POSTGRES_HOST: database.instanceEndpoint.hostname,
        POSTGRES_PORT: '5432',
        POSTGRES_DB: 'witcher_cc',
        POSTGRES_SSL: 'true',
        WCC_DEFAULT_CHARACTER_PATH: '/var/task/defaultCharacter.json',
        AUTH_MODE:
          cognitoJwtIssuer && cognitoJwtAudience.length > 0
            ? 'trust-apigw'
            : apiAuthModeOverride,
        AUTH_GOOGLE_CLIENT_IDS: process.env.WCC_GOOGLE_CLIENT_IDS ?? '',
        AUTH_PROTECT_HEALTH: 'true',
        NODE_OPTIONS: '--enable-source-maps',
      },
    });

    // Pass DB password from Secrets Manager
    if (database.secret) {
      apiFunction.addEnvironment('DB_SECRET_ARN', database.secret.secretArn);
      database.secret.grantRead(apiFunction);
    }

    const dbSeedOnEventFunction = new lambdaNodejs.NodejsFunction(
      this,
      'WccDbSeedFunction',
      {
        runtime: lambda.Runtime.NODEJS_20_X,
        entry: path.join(__dirname, '../lambda/db-seed-handler.ts'),
        handler: 'handler',
        depsLockFilePath: path.join(__dirname, '../../../package-lock.json'),
        projectRoot: path.join(__dirname, '../../..'),
        bundling: {
          sourceMap: true,
          target: 'node20',
          format: lambdaNodejs.OutputFormat.CJS,
          commandHooks: {
            beforeBundling() {
              return [];
            },
            beforeInstall() {
              return [];
            },
            afterBundling(inputDir, outputDir) {
              return [
                `node -e "const fs=require('fs'); const path=require('path'); const [inDir,outDir]=process.argv.slice(1); const src=path.join(inDir,'db','sql','wcc_sql_deploy.sql'); const dst=path.join(outDir,'wcc_sql_deploy.sql'); fs.copyFileSync(src,dst);" "${inputDir}" "${outputDir}"`,
              ];
            },
          },
        },
        memorySize: 1024,
        timeout: cdk.Duration.minutes(15),
        vpc,
        vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
        securityGroups: [lambdaSecurityGroup],
        environment: {
          POSTGRES_HOST: database.instanceEndpoint.hostname,
          POSTGRES_PORT: '5432',
          POSTGRES_DB: 'witcher_cc',
          NODE_OPTIONS: '--enable-source-maps',
        },
      },
    );

    if (database.secret) {
      dbSeedOnEventFunction.addEnvironment('DB_SECRET_ARN', database.secret.secretArn);
      database.secret.grantRead(dbSeedOnEventFunction);
    }

    const dbSeedProvider = new cr.Provider(this, 'WccDbSeedProvider', {
      onEventHandler: dbSeedOnEventFunction,
    });

    const dbSeedResource = new cdk.CustomResource(this, 'WccDbSeed', {
      serviceToken: dbSeedProvider.serviceToken,
      properties: {
        dbInstanceIdentifier: database.instanceIdentifier,
        sqlBundleVersion: 'wcc_sql_deploy_v1',
      },
    });
    dbSeedResource.node.addDependency(database);
    if (database.secret) {
      dbSeedResource.node.addDependency(database.secret);
    }
    dbSeedResource.node.addDependency(secretsManagerVpcEndpoint);
    apiFunction.node.addDependency(dbSeedResource);

    // ================================================================
    // 4. API GATEWAY (HTTP API)
    // ================================================================
    const httpApi = new apigw.HttpApi(this, 'WccHttpApi', {
      apiName: `${appName}-api`,
      corsPreflight: {
        allowOrigins: ['*'], // TODO: restrict to CloudFront domain
        allowMethods: [apigw.CorsHttpMethod.ANY],
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    // Budget/abuse protection baseline (without WAF):
    // keep limits high enough for the "auto-randomize until end" survey flow
    // which sends sequential /survey/next requests in a loop.
    const httpApiDefaultStage = httpApi.defaultStage?.node
      .defaultChild as apigw.CfnStage | undefined;
    if (httpApiDefaultStage) {
      httpApiDefaultStage.defaultRouteSettings = {
        throttlingRateLimit: 20,
        throttlingBurstLimit: 40,
      };
    }

    const jwtAuthorizer =
      cognitoJwtIssuer && cognitoJwtAudience.length > 0
        ? new apigwAuthorizers.HttpJwtAuthorizer(
            'WccCognitoJwtAuthorizer',
            cognitoJwtIssuer,
            {
              jwtAudience: cognitoJwtAudience,
            },
          )
        : undefined;

    httpApi.addRoutes({
      path: '/{proxy+}',
      methods: [apigw.HttpMethod.ANY],
      authorizer: jwtAuthorizer,
      integration: new apigwIntegrations.HttpLambdaIntegration(
        'ApiIntegration',
        apiFunction,
      ),
    });

    // ================================================================
    // 5. S3 (static frontend)
    // ================================================================
    // TODO: before deploying, run `npm run build` in cloud/web
    // so that out/ contains static HTML/JS/CSS.
    const siteBucket = new s3.Bucket(this, 'WccSiteBucket', {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    new s3deploy.BucketDeployment(this, 'DeploySite', {
      sources: [
        s3deploy.Source.asset(path.join(__dirname, '../../web/out')),
      ],
      destinationBucket: siteBucket,
    });

    // ================================================================
    // 6. CLOUDFRONT (CDN + routing)
    // ================================================================
    const distribution = new cloudfront.Distribution(this, 'WccCdn', {
      defaultBehavior: {
        origin: origins.S3BucketOrigin.withOriginAccessControl(siteBucket),
        viewerProtocolPolicy:
          cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
      additionalBehaviors: {
        '/api/*': {
          origin: new origins.HttpOrigin(
            `${httpApi.httpApiId}.execute-api.${this.region}.amazonaws.com`,
          ),
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          viewerProtocolPolicy:
            cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          originRequestPolicy:
            cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
        },
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 403,
          responsePagePath: '/index.html',
          responseHttpStatus: 200,
        },
        {
          httpStatus: 404,
          responsePagePath: '/index.html',
          responseHttpStatus: 200,
        },
      ],
    });

    // ================================================================
    // OUTPUTS
    // ================================================================
    new cdk.CfnOutput(this, 'SiteUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'Open this URL in a browser to see the app',
    });
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      description: 'Direct API URL (for debugging)',
    });
    new cdk.CfnOutput(this, 'DbEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'RDS endpoint (internal)',
    });
    new cdk.CfnOutput(this, 'SecretsManagerVpcEndpointId', {
      value: secretsManagerVpcEndpoint.vpcEndpointId,
      description: 'Interface VPC endpoint used by Lambda to reach Secrets Manager privately',
    });
  }
}
