export class DurationFormatter {
  private constructor() {}

  static format(minutes: number | null | undefined): string {
    const normalizedMinutes = Number(minutes ?? 0);

    if (!Number.isFinite(normalizedMinutes) || normalizedMinutes <= 0) {
      return 'Tempo a confirmar';
    }

    if (normalizedMinutes < 60) {
      return normalizedMinutes === 1 ? '1 minuto' : `${normalizedMinutes} minutos`;
    }

    const hours = Math.floor(normalizedMinutes / 60);
    const remainingMinutes = normalizedMinutes % 60;

    if (remainingMinutes === 0) {
      return hours === 1 ? '1 hora' : `${hours} horas`;
    }

    return `${hours}h${remainingMinutes.toString().padStart(2, '0')}`;
  }

  static estimated(minutes: number | null | undefined): string {
    const normalizedMinutes = Number(minutes ?? 0);

    if (!Number.isFinite(normalizedMinutes) || normalizedMinutes <= 0) {
      return 'Tempo a confirmar';
    }

    return `Estimativa de ${this.format(normalizedMinutes)}`;
  }
}
