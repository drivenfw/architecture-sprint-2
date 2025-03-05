#!/bin/bash

###
# # Инициализируем бд
###
 
docker compose exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

docker compose exec -T shard1a mongosh --port 27019 <<EOF
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id: 0, host : "shard1a:27019" },
      { _id: 1, host: "shard1b:27020" },
      { _id: 2, host: "shard1c:27021" }
    ]
  }
);
EOF

docker compose exec -T shard2a mongosh --port 27022 <<EOF
rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2a:27022" },
      { _id : 1, host : "shard2b:27023" },
      { _id : 2, host : "shard2c:27024" }
    ]
  }
);
EOF

docker compose exec -T mongos_router mongosh --port 27018 <<EOF
sh.addShard( "shard1/shard1a:27019,shard1b:27020,shard1c:27021");
sh.addShard( "shard2/shard2a:27022,shard2b:27023,shard2c:27024");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF
