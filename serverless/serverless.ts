import type { AWS } from '@serverless/typescript';

const serverlessConfiguration: AWS = {
  service: 'serverless',
  frameworkVersion: '3',
  plugins: ['serverless-esbuild'],
  provider: {
    name: 'aws',
    runtime: 'nodejs18.x',
    region: "ap-northeast-1",
    environment: {
      AWS_NODEJS_CONNECTION_REUSE_ENABLED: '1',
      NODE_OPTIONS: '--enable-source-maps --stack-trace-limit=1000',
    },
  },
  package: { individually: true },
  custom: {
    appSync: {
      name: "appsync-{opt:stage, self:provider.stage}", 
      authenticationType: "API_KEY",
      schema: "./src/graphql/schema.graphql",
      apiKeys: [
        {
          name: "test-api-key",
          expiresAfter: "30d"
        },
      ],
      dataSources: [
        // https://zenn.dev/merutin/articles/e1de2cbe575b13
        // https://github.com/sid88in/serverless-appsync-plugin/blob/master/doc/substitutions.md
        {
          type: "RELATIONAL_DATABASE",
          name: "RDS_DATA_SOURCE",
          config: {
            region: "ap-northeast-1",
            databaseName: "sample", // RDSのデータベース名
            dbClusterIdentifier: "sample", // RDSクラスターのARN
            awsSecretStoreArn: "arn:aws:secretsmanager:ap-northeast-1:xxxxxxxxxxxx:secret:sample", // RDSの認証情報を保存したSecretsManagerのARN
            // TODO: もっと絞る
            iamRoleStatements: [
              {
                Effect: "ALLOW",
                Action: [
                  "rds-data:ExecuteStatement",
                  "rds-data:BatchExecuteStatement",
                  "rds-data:BeginTransaction",
                  "rds-data:CommitTransaction",
                  "rds-data:RollbackTransaction",
                  "rds-data:AbortTransaction",
                ],
                Resource: "*",
              },
            ],
          },
        },
      ],
    },
    esbuild: {
      bundle: true,
      minify: false,
      sourcemap: true,
      exclude: ['aws-sdk'],
      target: 'node18',
      define: { 'require.resolve': undefined },
      platform: 'node',
      concurrency: 10,
    },
  },
};

module.exports = serverlessConfiguration;
