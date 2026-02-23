import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import { Construct } from 'constructs';

export interface WccDbOnlyStackProps extends cdk.StackProps {
  dbName: string;
  dbUsername: string;
  createSecretsManagerVpcEndpoint: boolean;
}

export class WccDbOnlyStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: WccDbOnlyStackProps) {
    super(scope, id, props);

    // ================================================================
    // 1) NETWORK (VPC)
    // ================================================================
    // NAT is intentionally disabled to keep costs down.
    // Lambda that sits in this VPC will not have "internet" egress;
    // access to AWS services should be done via VPC endpoints.
    const vpc = new ec2.Vpc(this, 'WccDbVpc', {
      maxAzs: 2,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: 'public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
        {
          name: 'isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          cidrMask: 24,
        },
      ],
    });

    if (props.createSecretsManagerVpcEndpoint) {
      new ec2.InterfaceVpcEndpoint(this, 'SecretsManagerEndpoint', {
        vpc,
        service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
        privateDnsEnabled: true,
        subnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      });
    }

    // ================================================================
    // 2) SECURITY GROUP (DB)
    // ================================================================
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'WccDbSecurityGroup', {
      vpc,
      description: 'Access control for WCC RDS PostgreSQL',
    });

    // Allow connections from within the VPC (e.g., Lambda in the same VPC).
    dbSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(vpc.vpcCidrBlock),
      ec2.Port.tcp(5432),
      'PostgreSQL from within VPC',
    );

    // ================================================================
    // 3) RDS (PostgreSQL)
    // ================================================================
    const database = new rds.DatabaseInstance(this, 'WccPostgres', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        ec2.InstanceSize.MICRO,
      ),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      publiclyAccessible: false,
      databaseName: props.dbName,
      credentials: rds.Credentials.fromGeneratedSecret(props.dbUsername),
      securityGroups: [dbSecurityGroup],
      multiAz: false,
      allocatedStorage: 20,
      storageType: rds.StorageType.GP3,
      maxAllocatedStorage: 50,
      enablePerformanceInsights: false,
      autoMinorVersionUpgrade: true,
      backupRetention: cdk.Duration.days(1),
      deleteAutomatedBackups: true,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
      deletionProtection: false,
    });

    // ================================================================
    // OUTPUTS (for other stacks / humans)
    // ================================================================
    // Keep export names stable across synth/deploy runs.
    // If you need multiple environments in the same account/region, deploy with different stack names.
    const exportPrefix = this.stackName;

    new cdk.CfnOutput(this, 'VpcId', {
      value: vpc.vpcId,
      exportName: `${exportPrefix}-VpcId`,
    });

    new cdk.CfnOutput(this, 'IsolatedSubnetIds', {
      value: vpc.isolatedSubnets.map((s) => s.subnetId).join(','),
      exportName: `${exportPrefix}-IsolatedSubnetIds`,
    });

    new cdk.CfnOutput(this, 'PublicSubnetIds', {
      value: vpc.publicSubnets.map((s) => s.subnetId).join(','),
      exportName: `${exportPrefix}-PublicSubnetIds`,
    });

    new cdk.CfnOutput(this, 'DbSecurityGroupId', {
      value: dbSecurityGroup.securityGroupId,
      exportName: `${exportPrefix}-DbSecurityGroupId`,
    });

    new cdk.CfnOutput(this, 'DbEndpointAddress', {
      value: database.instanceEndpoint.hostname,
      exportName: `${exportPrefix}-DbEndpointAddress`,
    });

    new cdk.CfnOutput(this, 'DbEndpointPort', {
      value: database.instanceEndpoint.port.toString(),
      exportName: `${exportPrefix}-DbEndpointPort`,
    });

    new cdk.CfnOutput(this, 'DbName', {
      value: props.dbName,
      exportName: `${exportPrefix}-DbName`,
    });

    if (database.secret) {
      new cdk.CfnOutput(this, 'DbSecretArn', {
        value: database.secret.secretArn,
        exportName: `${exportPrefix}-DbSecretArn`,
      });
    }

  }
}
