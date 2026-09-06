import { create } from 'zustand';
import { randomUUID } from 'expo-crypto';
import { ShiftInterval } from '@/domain/time/ShiftInterval';

/**
 * Phase 1 guest-mode shift state: in-memory only, matching the original
 * scope for this phase (docs/phases.md — "local-only (guest) mode"). Not a
 * persistence-layer decision: no AsyncStorage/MMKV is introduced here. Real
 * persistence arrives with the Firestore offline cache in the auth/sync
 * phase (docs/decisions/0001-migrate-flutter-to-react-native-expo.md) — see
 * AGENTS.md's hard rule against adding a local persistence layer before
 * confirming Firestore's offline cache can't cover the case.
 */
export interface Shift extends ShiftInterval {
  id: string;
  jobId: string | null;
  role: string;
  paidBreakMinutes: number;
  unpaidBreakMinutes: number;
}

export type NewShift = Omit<Shift, 'id'>;

interface ShiftsState {
  shifts: Shift[];
  addShift: (shift: NewShift) => Shift;
  updateShift: (id: string, patch: Partial<NewShift>) => void;
  deleteShift: (id: string) => void;
  clearAll: () => void;
}

export const useShiftsStore = create<ShiftsState>((set, get) => ({
  shifts: [],

  addShift: (shift) => {
    const created: Shift = { ...shift, id: randomUUID() };
    set({ shifts: [...get().shifts, created].sort((a, b) => (a.startUtc < b.startUtc ? -1 : 1)) });
    return created;
  },

  updateShift: (id, patch) => {
    set({
      shifts: get()
        .shifts.map((shift) => (shift.id === id ? { ...shift, ...patch } : shift))
        .sort((a, b) => (a.startUtc < b.startUtc ? -1 : 1)),
    });
  },

  deleteShift: (id) => {
    set({ shifts: get().shifts.filter((shift) => shift.id !== id) });
  },

  clearAll: () => set({ shifts: [] }),
}));

/** The first shift whose start is still in the future, relative to `nowIso`. */
export function selectNextShift(shifts: Shift[], nowIso: string): Shift | null {
  return shifts.find((shift) => shift.startUtc > nowIso) ?? null;
}
