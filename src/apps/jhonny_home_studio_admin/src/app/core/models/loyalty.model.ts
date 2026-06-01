export interface LoyaltyTransactionModel {
  id: string;
  appointmentId: string;
  points: number;
  description: string;
  createdAt: string;
}

export interface LoyaltyModel {
  customerId: string;
  points: number;
  level: string;
  nextLevel?: string | null;
  pointsToNextLevel: number;
  benefits: string[];
  recentTransactions: LoyaltyTransactionModel[];
}
