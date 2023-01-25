# GHES2GHES - sync repositories from one instance to another

Just a small set-up to get you forward in synchronising repositories accross multiple instances.

You will need to create GitHub Apps for both the source and the destination server.
If you need to back-up repositories, that are owned by individual users, make sure the App has the correct admin permissions to do so ;)

Source GitHub App:
Content: read

Destination GitHub App:
Content: write.


```yaml
name: Sync repos from SRC to DST

on:
  schedule:
  - cron: '13 2 * * *'
  workflow_dispatch:
  push:

jobs:
  sync-repo:
    uses: ./.github/workflows/sync-repo.yaml
    with:
      source-prefix: https://source.ghes.domain.com
      destination-prefix: https://destination.ghes.domain.com
      repolist-file: repolist.csv
    secrets:
      source-app-id: ${{ secrets.SRC_GHES_2_GHES_READ_ID }}
      source-app-secret: ${{ secrets.SRC_GHES_2_GHES_READ_KEY }}
      destination-app-id: ${{ secrets.DST_GHES_2_GHES_WRITE_ID }}
      destination-app-secret: ${{ secrets.DST_GHES_2_GHES_WRITE_KEY }}
```

note: This wil only sync the repositories, if they don't exist yet, you should extend it to create the them on the fly using the API.


```yaml
name: 'Sync repos between GitHub instances (only $default branches)'

on:
  workflow_call:
    inputs:
      repolist-file:
        description: 'Location of the repolist file with repos to be synced'
        required: true
        type: string
      source-prefix:
        description: 'Prefix of the source repos (e.g. https://source.ghes.domain.com)'
        required: true
        type: string
      destination-prefix:
        description: 'Prefix of the destination repos (e.g. https://destination.ghes.domain.com)'
        required: true
        type: string
    secrets:
      source-app-id:
        description: 'APP ID that can be used to check-out the source'
        required: true
      source-app-secret:
        description: 'Secret key (PEM) to use the source App'
        required: true
      destination-app-id:
        description: 'APP ID that can be used to check-out the destination'
        required: true
      destination-app-secret:
        description: 'Secret key (PEM) to use the destination App'
        required: true

jobs:
  sync-repo:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Determin GHES base URI for fetching the tokens
      id: base_uri
      run: |
        SOURCE_GHES_API=${{ inputs.source-prefix }}/api/v3
        DESTINATION_GHES_API=${{ inputs.destination-prefix }}/api/v3
        echo "::set-output name=source::$SOURCE_GHES_API"
        echo "::set-output name=destination::$DESTINATION_GHES_API"

    - name: Get source token
      id: get_source_token
      uses: peter-murray/workflow-application-token-action@v2
      with:
        application_id: ${{ secrets.source-app-id }}
        application_private_key: ${{ secrets.source-app-secret }}
        github_api_base_url: ${{ steps.base_uri.outputs.source }}
        organization: 'source-org'

    - name: Get destination token
      id: get_destination_token
      uses: peter-murray/workflow-application-token-action@v2
      with:
        application_id: ${{ secrets.destination-app-id }}
        application_private_key: ${{ secrets.destination-app-secret }}
        github_api_base_url: ${{ steps.base_uri.outputs.destination }}
        organization: 'destination-org'

    - name: 'Mirror source repo to destination'
      run: |
        export SOURCE_TOKEN=${{ steps.get_source_token.outputs.token }}
        export DESTINATION_TOKEN=${{ steps.get_destination_token.outputs.token }}
        ghes2ghes ${{ inputs.repolist-file }}
```