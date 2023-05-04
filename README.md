# AppSync-Tutorial
AppSyncのチュートリアル

## Aurora Serverlessクラスターの作成
```bash
sh ./scrips/create-aurora-serverless-cluster.sh
```

実行結果から.envに値を設定する
- `RDS cluster ARN`の値を環境変数の`DB_CLUSTER_ARN`に設定する
- `RDS cluster secret ARN`の値を環境変数の`DB_SECRET_ARN`に設定する

```bash
---------------------------------------------------
RDS cluster ARN: xxxxxxxx
RDS cluster secret ARN: yyyyyyyy
---------------------------------------------------
```

## RDS
- Aurora Serverlessクラスターの作成
- Data APIの作成
  - https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/data-api.html 
- テーブルの作成

## Serverless Framework
https://zenn.dev/merutin/articles/e1de2cbe575b13