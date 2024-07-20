import awswrangler as wr
import pandas as pd
import json

if __name__ == "__main__":

    dados = {
        "nome": "Paulo",
        "id": "2",
        "idade": 36,
        "dados": [{
            "cidade": "city", 
            "estado": "state"
        }]
    }

    dados = pd.DataFrame(dados)
    dados["dados"] = dados["dados"].apply(json.dumps)
    wr.s3.to_parquet(
        df=dados,
        path='s3://',
        dataset=True,
        database='paulo',
        table='paulo_table',
        partition_cols=['id', 'idade']
    )