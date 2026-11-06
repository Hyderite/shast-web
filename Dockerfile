FROM node:22-slim AS frontend-builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN npm install -g pnpm@10.15.1

WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

FROM golang:1.23-alpine AS backend-builder
WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

COPY --from=frontend-builder /app/dist ./frontend/dist

RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:3.20 AS runner
WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=backend-builder /app/main .

EXPOSE 2000

CMD ["./main"]
