FROM 167859589098.dkr.ecr.ap-southeast-2.amazonaws.com/eql-runner-tools/node:latest AS base
USER root

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
# RUN apk add --no-cache libc6-compat
# RUN npm config set proxy http://awsproxy.services.local:3128
# RUN yum update -y && \
#     yum install -y shadow-utils
# RUN npm install -g yarn
# RUN npm install -g pnpm
WORKDIR /app

# Install dependencies based on the preferred package manager
# RUN pnpm create next-app --example . nextjs-docker
COPY package*.json yarn.lock* pnpm-lock.yaml* ./
# RUN yarn install --frozen-lockfile
# RUN npm ci --omit=dev
# RUN pnpm i --frozen-lockfile
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules

COPY . .


# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN pnpm build

# If using npm comment out above and use below instead
# RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1

# RUN groupadd --system --gid 1001 nodejs
# RUN useradd --system --uid 1001 nextjs
USER actions-runner

WORKDIR /home/actions-runner

COPY --from=builder  /app/public ./public
COPY --from=builder /app/package.json ./package.json
# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 8080

ENV PORT 8080

CMD ["npm", "start"]







# FROM 167859589098.dkr.ecr.ap-southeast-2.amazonaws.com/eql-runner-tools/node:latest

# USER root

# WORKDIR /usr/src/app

# COPY package*.json ./

# RUN npm install --omit=dev

# COPY . .

# RUN npm run build

# EXPOSE 3000

# CMD ["npm", "start"]
