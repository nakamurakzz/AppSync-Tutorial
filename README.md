# AppSync-Tutorial
AppSyncをServerless Frameworkで構築してみる

## 環境変数用ファイルの作成
```bash
cp .env.sample .env.{dev|stg|prod}
```

## Aurora Serverlessクラスターの作成
- データベースのID/PWを.env.{dev|stg|prod}に設定する
  - `DB_USER`
  - `DB_PASSWORD`

```bash
sh ./scrips/create-aurora-serverless-cluster.sh
```

- 作成する環境を選択する
  - dev|stg|prod
- 作成するAWSアカウントのプロファイルを入力する

実行結果からSecretManagerのARNを.envに値を設定する
- `RDS cluster secret ARN`の値を環境変数の`DB_SECRET_ARN`に設定する

```bash
---------------------------------------------------
RDS cluster secret ARN: yyyyyyyy
---------------------------------------------------
```

- 作成する環境を選択する
  - dev|stg|prod
- 作成するAWSアカウントのプロファイルを入力する

## テーブル作成
```bash
sh ./scrips/create-sample-table.sh
```

- todosテーブルが作成される

## デプロイ
デプロイ
```bash
cd serverless
npm run deploy:{dev|stg|prod} --aws-profile {AWSアカウントのプロファイル名}
```