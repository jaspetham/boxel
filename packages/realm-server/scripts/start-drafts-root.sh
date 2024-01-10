#! /bin/sh

NODE_NO_WARNINGS=1 ts-node \
  --transpileOnly main \
  --port=4204 \
  \
  --path='../drafts-realm/' \
  --matrixURL='http://localhost:8008' \
  --username='drafts_realm' \
  --password='password' \
  --toUrl='/' \
  --fromUrl='https://cardstack.com/base/' \
  --toUrl='http://localhost:4201/base/'
