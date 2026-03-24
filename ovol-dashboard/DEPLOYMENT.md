# Deployment Guide

## Pre-Deployment Checklist

### Environment Setup
- [ ] Copy `.env.example` to `.env.production.local`
- [ ] Configure `NEXT_PUBLIC_API_BASE_URL` (production API URL)
- [ ] Obtain Mapbox API token and set `NEXT_PUBLIC_MAPBOX_TOKEN`
- [ ] Set `NEXT_PUBLIC_API_TOKEN` for authentication
- [ ] Configure `NEXT_PUBLIC_WS_URL` for WebSocket (production endpoint)
- [ ] Set `NODE_ENV=production`

### Code Quality
- [ ] Run TypeScript type check: `npm run lint`
- [ ] Test all pages locally: `npm run dev`
- [ ] Test on mobile devices/tablets
- [ ] Test with slow network (DevTools throttle)
- [ ] Verify form submissions work correctly
- [ ] Test WebSocket reconnection

### Features to Verify
- [ ] Dashboard loads KPI cards correctly
- [ ] Map initializes with Mapbox token
- [ ] Farmer search and filters work
- [ ] Orders Kanban board updates status
- [ ] Payments table verifies pending payments
- [ ] Analytics charts render properly
- [ ] Notifications appear on errors
- [ ] Sidebar collapse works on mobile

### API Integration
- [ ] All API endpoints are reachable
- [ ] Authentication tokens are valid
- [ ] CORS is properly configured
- [ ] WebSocket endpoint is accessible
- [ ] API error responses are handled

## Deployment Platforms

### Vercel (Recommended)
Vercel is optimized for Next.js applications.

1. **Connect Repository**
   ```
   - Push code to GitHub/GitLab
   - Import project in Vercel dashboard
   - Select root directory: ovol-dashboard
   ```

2. **Environment Variables**
   - Add production environment variables in Vercel settings
   - Create separate preview and production environments if needed

3. **Build Settings**
   - Build command: `npm run build`
   - Output directory: `.next`
   - Install command: `npm install`

4. **Deploy**
   ```
   - Vercel automatically deploys on push to main
   - Preview deployments for pull requests
   - Custom domains supported
   ```

### Docker Deployment

1. **Create Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source
COPY . .

# Build application
RUN npm run build

# Expose port
EXPOSE 3000

# Start server
CMD ["npm", "start"]
```

2. **Create .dockerignore**
```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.local
.next
.vercel
coverage
dist
```

3. **Build and Run**
```bash
docker build -t ovol-dashboard:1.0.0 .
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_API_BASE_URL=https://api.example.com/api \
  -e NEXT_PUBLIC_MAPBOX_TOKEN=your_token \
  -e NEXT_PUBLIC_WS_URL=wss://api.example.com/ws \
  ovol-dashboard:1.0.0
```

### AWS EC2

1. **Launch EC2 Instance**
   - Ubuntu 22.04 LTS
   - t3.medium or larger
   - Security groups: allow 80, 443, 22

2. **Setup Environment**
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Install Nginx for reverse proxy
sudo apt-get install -y nginx
```

3. **Deploy Application**
```bash
# Clone repository
git clone <repo-url> /home/ubuntu/ovol-dashboard
cd /home/ubuntu/ovol-dashboard

# Install and build
npm install
NEXT_PUBLIC_API_BASE_URL=https://api.example.com/api \
NEXT_PUBLIC_MAPBOX_TOKEN=your_token \
npm run build

# Start with PM2
pm2 start "npm start" --name ovol-dashboard
pm2 startup
pm2 save
```

4. **Configure Nginx**
```nginx
server {
    listen 80;
    server_name dashboard.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name dashboard.example.com;

    ssl_certificate /etc/letsencrypt/live/dashboard.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://localhost:3000/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

5. **SSL Certificate (Let's Encrypt)**
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d dashboard.example.com
sudo systemctl reload nginx
```

### Azure App Service

1. **Create App Service Plan**
```bash
az appservice plan create \
  --name ovol-dashboard-plan \
  --resource-group myResourceGroup \
  --sku B2 --is-linux

az webapp create \
  --resource-group myResourceGroup \
  --plan ovol-dashboard-plan \
  --name ovol-dashboard \
  --runtime "node|18-lts"
```

2. **Configure App Settings**
```bash
az webapp config appsettings set \
  --resource-group myResourceGroup \
  --name ovol-dashboard \
  --settings \
    NEXT_PUBLIC_API_BASE_URL=https://api.example.com/api \
    NEXT_PUBLIC_MAPBOX_TOKEN=your_token
```

3. **Deploy**
```bash
# Create deployment user
az webapp deployment user set \
  --user-name <username> \
  --password <password>

# Deploy from git
az webapp deployment source config-zip \
  --resource-group myResourceGroup \
  --name ovol-dashboard \
  --src ./ovol-dashboard.zip
```

## Post-Deployment

### Monitoring
- [ ] Set up application logs (Vercel/Azure/CloudWatch)
- [ ] Monitor API response times
- [ ] Track WebSocket connection issues
- [ ] Set up error alerting (Sentry, DataDog)

### Performance
- [ ] Check Core Web Vitals in Google PageSpeed Insights
- [ ] Monitor bundle size (should be < 200KB)
- [ ] Enable image optimization
- [ ] Review and optimize database queries

### Security
- [ ] Enable HTTPS/TLS
- [ ] Set Security headers (CSP, X-Frame-Options)
- [ ] Configure CORS properly
- [ ] Rotate API tokens regularly
- [ ] Monitor for suspicious activity

### Backup & Recovery
- [ ] Set up database backups
- [ ] Document rollback procedure
- [ ] Test disaster recovery plan
- [ ] Maintain deployment history

## Troubleshooting

### Map Not Loading
- Verify Mapbox token is valid and not expired
- Check browser console for token errors
- Ensure API domain is whitelisted in Mapbox settings

### WebSocket Connection Issues
- Check WebSocket endpoint is accessible
- Verify CORS headers on WebSocket server
- Check firewall rules for WSS (secure WebSocket)

### Slow Performance
- Check API response times
- Verify database indexes
- Review TanStack Query cache settings
- Monitor network requests

### Authentication Failures
- Verify API token is valid
- Check token format in Authorization header
- Ensure API server is running
- Review API logs for issues

## Scaling Considerations

### For Higher Load
- Use Next.js ISR (Incremental Static Regeneration) for dashboards
- Implement CDN for static assets (Cloudflare, CloudFront)
- Set up load balancing for multiple instances
- Optimize database queries with indexes
- Consider caching layer (Redis) for frequently accessed data

### Regional Deployment
- Deploy to multiple regions
- Use global load balancer
- Set up regional API endpoints
- Implement disaster recovery strategy

## Version Management

Tag releases:
```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

## Rollback Procedure

If issues occur:
```bash
# Revert to previous commit
git revert <commit-hash>
git push origin main

# Or rollback deployment
# On Vercel: Use "Deployments" tab to rollback
# On AWS: Re-deploy previous version
# On Docker: Deploy previous image tag
```
