import awswrangler as wr
import pandas as pd
import json

if __name__ == "__main__":

    dados = {
        "nome": "Paulo",
        "id": "1",
        "idade": 36,
        "data_new": [
            {
                "cidade": "city", 
                "estado": "state"
            }
        ]
    }

    dados_df = pd.DataFrame(dados)
    wr.s3.to_parquet(
        df=dados_df,
        path='s3://',
        dataset=True,
        database='paulo',
        table='paulo_table',
        partition_cols=['id', 'idade']
    )
