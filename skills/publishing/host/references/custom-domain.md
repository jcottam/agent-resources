# Custom Domain for R2

Replace the default `pub-xxx.r2.dev` URL with your own domain (e.g., `assets.yourdomain.com`).

## Steps

### 1. Connect the domain in Cloudflare

1. Open the [Cloudflare dashboard](https://dash.cloudflare.com).
2. Navigate to **R2 Object Storage** > your bucket > **Settings** > **Public access**.
3. Under **Custom Domains**, click **Connect Domain**.
4. Enter your subdomain (e.g., `assets.yourdomain.com`).
5. Cloudflare automatically creates the required DNS record. Confirm and wait for the SSL certificate to provision (usually under a minute).

Your domain must already be on Cloudflare DNS (orange-clouded) for this to work.

### 2. Update your publish config

Edit `~/.publish.json` and change `publicBaseUrl` to your custom domain:

```json
{
  "bucket": "my-bucket",
  "publicBaseUrl": "https://assets.yourdomain.com"
}
```

All future publishes will use this domain. Previously published URLs at `r2.dev` continue to work unless you disable the R2.dev subdomain in the dashboard.

### 3. (Optional) Disable the r2.dev URL

If you want all access to go through your custom domain:

1. In the bucket settings under **Public access**, find the **R2.dev subdomain** toggle.
2. Disable it.

Existing links using the `r2.dev` URL will stop working after this.

## Cache and headers

Custom domains on R2 automatically go through Cloudflare's CDN. You can configure cache behavior and custom headers with **Cache Rules** and **Transform Rules** in the Cloudflare dashboard under your domain's settings.

Common headers to set via Transform Rules:

| Header | Value | Purpose |
|--------|-------|---------|
| `Cache-Control` | `public, max-age=31536000, immutable` | Long-lived caching for hashed assets |
| `Cache-Control` | `public, max-age=3600` | Short caching for HTML that may change |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME-type sniffing |

## CORS

If published assets need to be loaded from other origins (e.g., embedding an HTML file in an iframe), configure CORS on the bucket:

1. In the bucket settings, find **CORS Policy**.
2. Add a rule allowing the origins you need, or use `*` for unrestricted access.

Example policy:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 86400
  }
]
```
