#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { WccDbOnlyStack } from '../lib/wcc-db-only-stack';

const app = new cdk.App();

const dbName = String(app.node.tryGetContext('dbName') ?? 'witcher_cc');
const dbUsername = String(app.node.tryGetContext('dbUsername') ?? 'cc_user');

const createSecretsManagerVpcEndpoint =
  app.node.tryGetContext('createSecretsManagerVpcEndpoint') !== false;

new WccDbOnlyStack(app, 'WccDbOnlyStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? 'eu-central-1',
  },
  dbName,
  dbUsername,
  createSecretsManagerVpcEndpoint,
});
