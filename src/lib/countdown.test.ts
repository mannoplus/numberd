import { describe, it, expect } from 'vitest'
import { getNextDrawDate, formatCountdown } from './countdown'

describe('Next Draw Countdown Logic', () => {
  describe('Lotto 6/49 (大樂透) - Tue/Fri 21:00 UTC+8', () => {
    it('counts down to today draw when before draw time on a draw day (Tuesday 20:45)', () => {
      // 2026-06-30 is Tuesday. 12:45:00 UTC is 20:45:00 UTC+8
      const now = new Date('2026-06-30T12:45:00Z')
      const nextDraw = getNextDrawDate('lotto_649', now)
      // Expected next draw: Tuesday 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-30T13:00:00.000Z')
    })

    it('switches to next draw day when after draw time on a draw day (Tuesday 21:01)', () => {
      // Tuesday 21:01:00 UTC+8 -> 13:01:00 UTC
      const now = new Date('2026-06-30T13:01:00Z')
      const nextDraw = getNextDrawDate('lotto_649', now)
      // Expected next draw: Friday July 3, 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-07-03T13:00:00.000Z')
    })

    it('handles non-draw day (Wednesday 20:00)', () => {
      // 2026-07-01 is Wednesday. 12:00:00 UTC is 20:00:00 UTC+8
      const now = new Date('2026-07-01T12:00:00Z')
      const nextDraw = getNextDrawDate('lotto_649', now)
      // Expected next draw: Friday July 3, 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-07-03T13:00:00.000Z')
    })

    it('handles transition from Friday night to Tuesday (Friday 21:15)', () => {
      // 2026-07-03 is Friday. 13:15:00 UTC is 21:15:00 UTC+8
      const now = new Date('2026-07-03T13:15:00Z')
      const nextDraw = getNextDrawDate('lotto_649', now)
      // Expected next draw: Tuesday July 7, 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-07-07T13:00:00.000Z')
    })

    it('handles exactly on draw time (Tuesday 21:00:00)', () => {
      // Tuesday 21:00:00 UTC+8 -> 13:00:00 UTC
      const now = new Date('2026-06-30T13:00:00Z')
      const nextDraw = getNextDrawDate('lotto_649', now)
      // Exactly at draw time: should automatically switch to next draw (Friday 21:00 UTC+8)
      expect(nextDraw.toISOString()).toBe('2026-07-03T13:00:00.000Z')
    })
  })

  describe('Lotto 6/38 (威力彩) - Mon/Thu 21:00 UTC+8', () => {
    it('counts down to today draw when before draw time on Thursday (Thursday 20:50)', () => {
      // 2026-06-25 is Thursday. 12:50:00 UTC is 20:50:00 UTC+8
      const now = new Date('2026-06-25T12:50:00Z')
      const nextDraw = getNextDrawDate('super_lotto_638', now)
      // Expected next draw: Thursday 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-25T13:00:00.000Z')
    })

    it('switches to next draw day when after draw time on Thursday (Thursday 21:05)', () => {
      // Thursday 21:05:00 UTC+8 -> 13:05:00 UTC
      const now = new Date('2026-06-25T13:05:00Z')
      const nextDraw = getNextDrawDate('super_lotto_638', now)
      // Expected next draw: Monday June 29, 21:00 UTC+8 -> 13:00:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-29T13:00:00.000Z')
    })
  })

  describe('Daily Cash (今彩539) - Mon-Sat 20:30 UTC+8', () => {
    it('counts down to today draw when before draw time on Saturday (Saturday 19:00)', () => {
      // 2026-06-27 is Saturday. 11:00:00 UTC is 19:00:00 UTC+8
      const now = new Date('2026-06-27T11:00:00Z')
      const nextDraw = getNextDrawDate('daily_cash_539', now)
      // Expected next draw: Saturday 20:30 UTC+8 -> 12:30:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-27T12:30:00.000Z')
    })

    it('switches to Monday draw when after draw time on Saturday (Saturday 20:31)', () => {
      // Saturday 20:31:00 UTC+8 -> 12:31:00 UTC
      const now = new Date('2026-06-27T12:31:00Z')
      const nextDraw = getNextDrawDate('daily_cash_539', now)
      // Expected next draw: Monday June 29, 20:30 UTC+8 (Sunday is skipped) -> 12:30:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-29T12:30:00.000Z')
    })

    it('handles Sunday correctly by pointing to Monday draw (Sunday 12:00)', () => {
      // 2026-06-28 is Sunday.
      const now = new Date('2026-06-28T12:00:00Z')
      const nextDraw = getNextDrawDate('daily_cash_539', now)
      // Expected next draw: Monday June 29, 20:30 UTC+8 -> 12:30:00 UTC
      expect(nextDraw.toISOString()).toBe('2026-06-29T12:30:00.000Z')
    })
  })

  describe('Countdown Formatting', () => {
    it('formats times less than 24 hours as HH:MM:SS', () => {
      const diffMs = (5 * 3600 + 30 * 60 + 15) * 1000 // 5h 30m 15s
      expect(formatCountdown(diffMs)).toBe('05:30:15')
    })

    it('formats times greater than 24 hours as Xd HH:MM:SS', () => {
      const diffMs = (1 * 86400 + 4 * 3600 + 12 * 60 + 5) * 1000 // 1d 4h 12m 5s
      expect(formatCountdown(diffMs)).toBe('1d 04:12:05')
    })

    it('returns 00:00:00 when difference is zero or negative', () => {
      expect(formatCountdown(0)).toBe('00:00:00')
      expect(formatCountdown(-5000)).toBe('00:00:00')
    })
  })
})
