# bucket-publish-jar

Publica um JAR em um ou mais buckets de Object Storage, gravando a versão como metadado. Implementação atual: **OCI Object Storage**.

A interface da action é provider-agnostic — uma migração futura para outro provedor não exige mudança nos workflows consumidores, apenas no conteúdo do secret de credenciais e na implementação interna da action.

> **Nota:** esta é uma _composite action_ (consumida a nível de **step** com `uses:`), diferente das _reusable workflows_ deste repositório que são consumidas a nível de **job**.

## Uso

```yaml
- name: Publish JAR
  uses: vrsoftbr/reusable-workflows/bucket-publish-jar@main
  with:
    credentials: ${{ secrets.BUCKET_PUBLISH_CREDENTIALS }}
    file:        dist/MeuApp.jar
    object-name: MeuApp.jar
    buckets:     'vr_4_4 vr_releases'
    version:     '4.4.79'
```

## Inputs

| Input | Obrigatório | Descrição |
|---|---|---|
| `credentials` | sim | JSON com as credenciais do provedor. Veja [formato abaixo](#formato-do-secret-bucket_publish_credentials). |
| `file` | sim | Caminho local do arquivo a publicar. |
| `object-name` | sim | Nome do objeto no bucket. |
| `buckets` | sim | Lista de buckets separada por espaço. |
| `version` | sim | Versão a ser gravada como metadado `versao`. |

## Formato do secret `BUCKET_PUBLISH_CREDENTIALS`

JSON único contendo todos os campos. **Recomenda-se configurá-lo como Organization Secret** com visibilidade restrita aos repositórios privados:

```json
{
  "user": "ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenancy": "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "fingerprint": "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99",
  "region": "sa-saopaulo-1",
  "key_content_b64": "<base64 do PEM completo>"
}
```

### Como gerar o `key_content_b64`

A partir do arquivo PEM apontado em `key_file` do seu `~/.oci/config`:

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\.oci\oci_api_key.pem"))
```

```bash
# Linux/macOS
base64 -w0 < ~/.oci/oci_api_key.pem
```

Cole a saída (linha única) no campo `key_content_b64`.

## Metadados gravados

Cada objeto recebe o metadado `versao` com o valor de `inputs.version`.

Ao ler via API OCI, o header é `opc-meta-versao`.

> **Nota de migração:** o pipeline anterior em GCS usava o header `x-goog-meta-versao`. Consumidores que liam esse header explicitamente precisam ser ajustados.
