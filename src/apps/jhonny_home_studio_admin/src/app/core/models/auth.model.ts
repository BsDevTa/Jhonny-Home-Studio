export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthUser {
  token: string;
  expiresAt: string;
  userId: string;
  fullName: string;
  email: string;
  role: string;
}
