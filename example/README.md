# Example Guide

Run with environment defines:

```bash
dart run example/basic_login_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>
```

Available demos:

- `basic_login_demo.dart`: Minimal login + session/context output
- `error_handling_demo.dart`: Catch each typed exception
- `context_workflow_demo.dart`: Refresh/switch context and call context-aware endpoint
- `file_download_demo.dart`: Download binary and save to temp folder
- `auto_session_renewal_demo.dart`: Demonstrate session polling with auto-renew support
- `api_catalog_demo.dart`: Browse 65 endpoint IDs and call catalog-based APIs

Safety note:

- Use read-only endpoints only when testing with real accounts.
- Do not hardcode credentials in source code.
