import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigwIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import { Construct } from 'constructs';
import * as path from 'path';

export class WccStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ================================================================
    // 1. NETWORK (VPC)
    // ================================================================
    // Virtual private cloud — isolated network for RDS + Lambda
    const vpc = new ec2.Vpc(this, 'WccVpc', {
      maxAzs: 2,
      natGateways: 1,
    });

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
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      databaseName: 'witcher_cc',
      credentials: rds.Credentials.fromGeneratedSecret('cc_user'),
      multiAz: false,
      allocatedStorage: 20,
      maxAllocatedStorage: 50,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
    });

    // ================================================================
    // 3. LAMBDA (API)
    // ================================================================
    // TODO: before deploying, run `npm run build` in cloud/api
    // so that dist/ contains compiled JS.
    const apiFunction = new lambda.Function(this, 'WccApiFunction', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'dist/lambda.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../api'), {
        exclude: ['node_modules/.cache', 'src', '*.ts', 'tsconfig.json'],
      }),
      memorySize: 256,
      timeout: cdk.Duration.seconds(29),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      environment: {
        POSTGRES_HOST: database.instanceEndpoint.hostname,
        POSTGRES_PORT: '5432',
        POSTGRES_DB: 'witcher_cc',
        POSTGRES_SSL: 'true',
        NODE_OPTIONS: '--enable-source-maps',
      },
    });

    // Pass DB password from Secrets Manager
    if (database.secret) {
      apiFunction.addEnvironment('DB_SECRET_ARN', database.secret.secretArn);
      database.secret.grantRead(apiFunction);
    }

    database.connections.allowDefaultPortFrom(apiFunction);

    // ================================================================
    // 4. API GATEWAY (HTTP API)
    // ================================================================
    const httpApi = new apigw.HttpApi(this, 'WccHttpApi', {
      apiName: 'wcc-api',
      corsPreflight: {
        allowOrigins: ['*'], // TODO: restrict to CloudFront domain
        allowMethods: [apigw.CorsHttpMethod.ANY],
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    httpApi.addRoutes({
      path: '/{proxy+}',
      methods: [apigw.HttpMethod.ANY],
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
  }
}
