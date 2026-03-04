#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { WccStack } from '../lib/wcc-stack';

const app = new cdk.App();
new WccStack(app, 'WccStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? 'eu-central-1',
  },
});
