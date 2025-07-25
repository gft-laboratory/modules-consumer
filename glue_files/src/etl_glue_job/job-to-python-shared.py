import boto3
import pandas as pd
import io

s3 = boto3.client('s3')

# Caminhos S3
input_bucket = "lake-teste-hdi-dev"
input_key = "raw/input_data.csv"
output_key = "processed/cleaned_data.csv"

# Leitura do CSV do S3
response = s3.get_object(Bucket=input_bucket, Key=input_key)
df = pd.read_csv(io.BytesIO(response['Body'].read()))

# Transformações em pandas
df_clean = df.dropna()

if "created_at" in df_clean.columns:
    df_clean["created_at"] = pd.to_datetime(df_clean["created_at"])

# Salvando resultado de volta no S3
out_buffer = io.BytesIO()
df_clean.to_csv(out_buffer, index=False)
s3.put_object(Bucket=input_bucket, Key=output_key, Body=out_buffer.getvalue())
