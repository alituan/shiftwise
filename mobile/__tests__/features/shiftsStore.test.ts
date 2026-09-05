import { act, renderHook } from '@testing-library/react-native';
import { NewShift, selectNextShift, Shift, useShiftsStore } from '@/features/schedule/shiftsStore';

const newShift: NewShift = {
  startUtc: '2026-06-01T14:00:00.000Z',
  endUtc: '2026-06-01T22:00:00.000Z',
  timeZone: 'America/New_York',
  jobId: null,
  role: 'Barista',
  paidBreakMinutes: 0,
  unpaidBreakMinutes: 30,
};

describe('useShiftsStore', () => {
  beforeEach(() => {
    useShiftsStore.setState({ shifts: [] });
  });

  it('adds a shift and assigns it an id', async () => {
    const { result } = await renderHook(() => useShiftsStore());
    let created!: Shift;
    await act(() => {
      created = result.current.addShift(newShift);
    });
    expect(result.current.shifts).toHaveLength(1);
    expect(result.current.shifts[0].id).toBe(created.id);
    expect(result.current.shifts[0].role).toBe('Barista');
  });

  it('keeps shifts sorted by start time after insert', async () => {
    const { result } = await renderHook(() => useShiftsStore());
    await act(() => {
      result.current.addShift({
        ...newShift,
        startUtc: '2026-06-03T14:00:00.000Z',
        endUtc: '2026-06-03T22:00:00.000Z',
      });
      result.current.addShift({
        ...newShift,
        startUtc: '2026-06-01T14:00:00.000Z',
        endUtc: '2026-06-01T22:00:00.000Z',
      });
      result.current.addShift({
        ...newShift,
        startUtc: '2026-06-02T14:00:00.000Z',
        endUtc: '2026-06-02T22:00:00.000Z',
      });
    });
    expect(result.current.shifts.map((s: Shift) => s.startUtc)).toEqual([
      '2026-06-01T14:00:00.000Z',
      '2026-06-02T14:00:00.000Z',
      '2026-06-03T14:00:00.000Z',
    ]);
  });

  it('updates a shift by id', async () => {
    const { result } = await renderHook(() => useShiftsStore());
    let created!: Shift;
    await act(() => {
      created = result.current.addShift(newShift);
    });
    await act(() => {
      result.current.updateShift(created.id, { role: 'Shift lead' });
    });
    expect(result.current.shifts[0].role).toBe('Shift lead');
  });

  it('deletes a shift by id', async () => {
    const { result } = await renderHook(() => useShiftsStore());
    let created!: Shift;
    await act(() => {
      created = result.current.addShift(newShift);
    });
    await act(() => {
      result.current.deleteShift(created.id);
    });
    expect(result.current.shifts).toHaveLength(0);
  });

  it('clearAll empties the store', async () => {
    const { result } = await renderHook(() => useShiftsStore());
    await act(() => {
      result.current.addShift(newShift);
      result.current.clearAll();
    });
    expect(result.current.shifts).toHaveLength(0);
  });
});

describe('selectNextShift', () => {
  const shifts: Shift[] = [
    {
      ...newShift,
      id: '1',
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
    },
    {
      ...newShift,
      id: '2',
      startUtc: '2026-06-03T14:00:00.000Z',
      endUtc: '2026-06-03T22:00:00.000Z',
    },
  ];

  it('returns the first shift starting after now', () => {
    const next = selectNextShift(shifts, '2026-06-02T00:00:00.000Z');
    expect(next?.id).toBe('2');
  });

  it('returns null when no shift is in the future', () => {
    const next = selectNextShift(shifts, '2026-12-31T00:00:00.000Z');
    expect(next).toBeNull();
  });
});
