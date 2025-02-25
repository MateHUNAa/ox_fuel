import { Station } from "@/types/station";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

const stationSlice = createSlice({
  initialState: {
    data: null as Station | null,
  },
  name: "station",
  reducers: {
    setStation: (state, action: PayloadAction<Station>) => {
      state.data = action.payload;
    },
  },
});
export const { setStation } = stationSlice.actions;
export default stationSlice.reducer;
