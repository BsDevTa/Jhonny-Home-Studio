import { ApiConfig } from '../config/api-config';

export function resolveMediaUrl(value?: string | null): string {
  const url = (value ?? '').trim();
  if (!url || url.startsWith('blob:')) {
    return '';
  }

  try {
    const parsed = new URL(url);
    if (parsed.protocol) {
      return url;
    }
  } catch {
    // Treat as relative below.
  }

  const normalizedPath = url.startsWith('/') ? url : `/${url}`;
  return `${ApiConfig.baseUrl}${normalizedPath}`;
}
