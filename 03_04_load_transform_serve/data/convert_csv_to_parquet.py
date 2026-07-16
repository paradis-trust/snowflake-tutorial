import json

import pandas as pd


def main() -> None:
    df = pd.read_csv("product_catalog_source.csv", escapechar="\\")
    df["attributes"] = df["attributes"].apply(json.loads)
    df.to_parquet("product_catalog_source.parquet")


if __name__ == "__main__":
    main()
