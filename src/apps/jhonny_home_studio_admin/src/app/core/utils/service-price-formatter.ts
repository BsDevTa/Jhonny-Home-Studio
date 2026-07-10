export class ServicePriceFormatter {
  private constructor() {}

  static startingAt(value: number | null | undefined): string {
    return `A partir de ${this.formatCurrency(Number(value ?? 0))}`;
  }

  private static formatCurrency(value: number): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
      .format(value)
      .replace(/\u00a0/g, ' ');
  }
}
