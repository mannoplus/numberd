export interface DrawSchedule {
  drawDays: number[]; // 0 = Sunday, 1 = Monday, etc.
  drawHour: number;   // 20 or 21
  drawMinute: number; // 0 or 30
}

export const GAME_SCHEDULES: Record<string, DrawSchedule> = {
  super_lotto_638: { drawDays: [1, 4], drawHour: 21, drawMinute: 0 }, // Mon, Thu at 21:00
  lotto_649: { drawDays: [2, 5], drawHour: 21, drawMinute: 0 },       // Tue, Fri at 21:00
  daily_cash_539: { drawDays: [1, 2, 3, 4, 5, 6], drawHour: 20, drawMinute: 30 } // Mon-Sat at 20:30
};

/**
 * Returns a new Date object representing the time in Taiwan Standard Time (UTC+8)
 * represented in the Date's UTC fields.
 */
export function getTaiwanDate(now: Date): Date {
  const utcTimestamp = now.getTime();
  const taiwanTimestamp = utcTimestamp + 8 * 60 * 60 * 1000;
  return new Date(taiwanTimestamp);
}

/**
 * Calculates the next draw date and time for a given game ID based on the official Taiwan Lottery schedule.
 * Returns a standard Date object representing the actual UTC/local moment in time of the next draw.
 */
export function getNextDrawDate(gameId: string, now: Date): Date {
  const schedule = GAME_SCHEDULES[gameId];
  if (!schedule) {
    throw new Error(`Unknown game ID: ${gameId}`);
  }

  const { drawDays, drawHour, drawMinute } = schedule;
  const taiwanDate = getTaiwanDate(now);
  const currentDay = taiwanDate.getUTCDay();
  const currentHour = taiwanDate.getUTCHours();
  const currentMinute = taiwanDate.getUTCMinutes();

  let selectedOffset = 0;

  for (let d = 0; d <= 7; d++) {
    const targetDayOfWeek = (currentDay + d) % 7;
    if (drawDays.includes(targetDayOfWeek)) {
      if (d === 0) {
        // Today is a draw day. Check if the current Taiwan time is before the draw time.
        if (
          currentHour < drawHour ||
          (currentHour === drawHour && currentMinute < drawMinute)
        ) {
          selectedOffset = 0;
          break;
        }
      } else {
        // Future draw day
        selectedOffset = d;
        break;
      }
    }
  }

  // Construct target draw Date in Taiwan representation
  const targetDrawDate = new Date(taiwanDate);
  targetDrawDate.setUTCHours(drawHour, drawMinute, 0, 0);
  targetDrawDate.setUTCDate(targetDrawDate.getUTCDate() + selectedOffset);

  // Convert Taiwan representation back to actual UTC epoch timestamp
  const realTargetDrawTime = targetDrawDate.getTime() - 8 * 60 * 60 * 1000;
  return new Date(realTargetDrawTime);
}

/**
 * Formats the millisecond difference into a countdown string.
 * Format: "Xd HH:MM:SS" if days > 0, otherwise "HH:MM:SS".
 */
export function formatCountdown(diffMs: number): string {
  if (diffMs <= 0) {
    return '00:00:00';
  }

  const totalSeconds = Math.floor(diffMs / 1000);
  const seconds = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const minutes = totalMinutes % 60;
  const totalHours = Math.floor(totalMinutes / 60);
  const hours = totalHours % 24;
  const days = Math.floor(totalHours / 24);

  const hh = String(hours).padStart(2, '0');
  const mm = String(minutes).padStart(2, '0');
  const ss = String(seconds).padStart(2, '0');

  if (days > 0) {
    return `${days}d ${hh}:${mm}:${ss}`;
  }
  return `${hh}:${mm}:${ss}`;
}
