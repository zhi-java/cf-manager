import { Request, Response, NextFunction } from 'express';
import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import path from 'path';

const logDir = process.env.V1_LOG_DIR || path.join(__dirname, '..', '..', 'data', 'logs');

const transport = new DailyRotateFile({
  dirname: logDir,
  filename: 'v1-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '7d',
  zippedArchive: false,
});

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, message }) => `${timestamp} ${message}`),
  ),
  transports: [transport],
});

export function v1RequestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const { method, originalUrl } = req;

  const bodySnippet = req.body
    ? JSON.stringify(req.body).slice(0, 200)
    : '';

  let logged = false;

  function log(suffix?: string) {
    if (logged) return;
    logged = true;
    const duration = Date.now() - start;
    const tag = suffix ? ` [${suffix}]` : '';
    logger.info(
      `${method} ${originalUrl} ${res.statusCode} ${duration}ms${tag}` +
      (bodySnippet ? ` body=${bodySnippet}` : ''),
    );
  }

  res.on('finish', () => log());
  res.on('close', () => {
    if (!res.writableFinished) log('client_disconnected');
  });

  next();
}
