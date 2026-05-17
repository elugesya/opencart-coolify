# Deploy OpenCart 3.x to Coolify

This guide walks you through deploying OpenCart 3.x with the iyzico payment plugin on your self-hosted Coolify instance.

## Prerequisites

- A running Coolify instance (v4+)
- A Git repository to push this project
- A domain name pointing to your Coolify server (optional but recommended)

## Project Structure

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds PHP 7.4 + Apache with OpenCart 3.0.3.9 and iyzico plugin |
| `docker-compose.yml` | Local development stack |
| `coolify-compose.yml` | Optimized for Coolify deployment |
| `entrypoint.sh` | Container startup script (creates config files, sets permissions) |
| `opencart.ini` | PHP runtime configuration |
| `.env.example` | Environment variables template |
| `upload/` | iyzico payment gateway extension files |

## Step 1: Prepare Environment Variables

Create a `.env` file locally (for reference) and prepare the same values for Coolify:

```env
# App Settings
APP_URL=https://your-domain.com

# Database Settings
DB_ROOT_PASSWORD=your_strong_root_password
DB_DATABASE=opencart
DB_USERNAME=opencart
DB_PASSWORD=your_strong_db_password
DB_PREFIX=oc_
```

> **Security Note:** Use strong, unique passwords. Coolify can auto-generate these in the UI.

## Step 2: Push to Git Repository

```bash
git init
git add .
git commit -m "Initial OpenCart 3.x + iyzico Coolify deployment"
git remote add origin <your-repo-url>
git push -u origin main
```

## Step 3: Create Resource in Coolify

1. Open your Coolify dashboard
2. Click **"+ New Resource"**
3. Choose **"Docker Compose"**
4. Select your Git repository
5. For **"Docker Compose File"**, use: `coolify-compose.yml`
6. Click **"Continue"**

## Step 4: Configure Environment Variables

In the Coolify resource settings, add the following environment variables:

| Variable | Example Value | Description |
|----------|---------------|-------------|
| `APP_URL` | `https://shop.yourdomain.com` | Your public domain |
| `DB_ROOT_PASSWORD` | `super_secret_root_pw` | MariaDB root password |
| `DB_DATABASE` | `opencart` | Database name |
| `DB_USERNAME` | `opencart` | Database user |
| `DB_PASSWORD` | `super_secret_db_pw` | Database password |
| `DB_PREFIX` | `oc_` | Table prefix |

> If you set a domain in Coolify, `SERVICE_FQDN_OPENCART` will be auto-populated.

## Step 5: Deploy

1. Click **"Deploy"** in Coolify
2. Wait for the build and deployment to complete (2-5 minutes)
3. Once running, visit your domain

## Step 6: OpenCart Web Installer

On first visit, OpenCart will automatically redirect to the installation wizard:

1. **License** — Accept and continue
2. **Pre-Installation** — All checks should pass (the container handles permissions)
3. **Configuration** — Enter the database credentials shown in your container logs:
   - **Database Driver:** MySQLi
   - **Hostname:** `db`
   - **Username:** `opencart` (matches `DB_USERNAME`)
   - **Password:** Your `DB_PASSWORD`
   - **Database:** `opencart`
   - **Port:** `3306`
   - **Prefix:** `oc_`
4. **Admin Account** — Create your store admin credentials
5. **Finish** — Installation complete

> **Important:** After installation, you **must manually remove** the `install/` directory for security. You can do this via Coolify's container terminal:
> ```bash
> rm -rf /var/www/html/install
> ```
> Or restart the container in Coolify after removing the directory.

## Step 7: Install iyzico Plugin

The iyzico plugin is **not pre-installed** in the Docker image (to keep the build repo-independent). Install it after OpenCart is running:

1. Download `iyzico.ocmod.zip` from the [iyzico GitHub releases](https://github.com/iyzico/iyzipay-opencart) or your local copy
2. Log in to OpenCart Admin (`/admin`)
3. Go to **Extensions → Installer**
4. Upload `iyzico.ocmod.zip`
5. Go to **Extensions → Extensions**
6. Choose **"Payments"** from the dropdown
7. Find **"iyzico"** and click **"Install"**
8. Click **"Edit"** to configure:
   - API Key (from iyzico merchant panel)
   - Secret Key (from iyzico merchant panel)
   - Test/Live mode
   - Other settings

> **Alternative:** If you want the iyzico plugin baked into the image, add the `upload/` folder (extracted from `iyzico.ocmod.zip`) to this repo and uncomment the `COPY upload/` line in the `Dockerfile`.

## Persistent Data

The following data persists across deployments via Docker volumes:

| Volume | Path | Contents |
|--------|------|----------|
| `opencart_image` | `/var/www/html/image/` | Product images, cache |
| `opencart_storage` | `/var/www/html/system/storage/` | Logs, cache, sessions, uploads |
| `db_data` | `/var/lib/mysql` | MariaDB database files |

## Local Testing (Optional)

Test locally before deploying to Coolify:

```bash
cp .env.example .env
# Edit .env with your values
docker-compose up -d
```

Access at: `http://localhost:8080`

To stop:
```bash
docker-compose down
```

To stop and remove volumes:
```bash
docker-compose down -v
```

## Troubleshooting

### Permission Denied on image/storage directories
Restart the container. The entrypoint script fixes permissions on every start.

### Database connection failed during install
- Ensure the `db` service is healthy before accessing OpenCart
- Check that environment variables match between services
- Verify MariaDB is running: `docker logs opencart-db`

### 500 Internal Server Error
Check Apache/PHP logs:
```bash
docker logs opencart-app
```

### Config files not created automatically
The entrypoint does **not** auto-create config files by default (to allow the web installer to run properly). The installer will create `config.php` and `admin/config.php` during Step 3. If you need to restore configs from environment variables (e.g., for disaster recovery), set `AUTO_CREATE_CONFIG=true` and restart the container.

## Updating OpenCart

To update OpenCart version:
1. Change the download URL in `Dockerfile`
2. Commit and push
3. Redeploy in Coolify

> **Warning:** Always back up your database and persistent volumes before updating.
