import { BlobOptions } from "buffer";
import { KeyboardEvent, useEffect, useRef } from "react";
import { noop } from "@/utils/misc";
import { useAppDispatch } from "@/store";
import { fetchNui } from "@/utils/fetchNui";

type FrameVisibleSetter = (bool: boolean) => void;

const LISTENED_KEYS = ["Escape"];

export const useExitListener = (visibleSetter: FrameVisibleSetter) => {
  const setterRef = useRef<FrameVisibleSetter>(noop);
  const dispatch = useAppDispatch();

  useEffect(() => {
    setterRef.current = visibleSetter;
  }, [visibleSetter]);

  useEffect(() => {
    const keyHandler = (e: any) => {
      if (LISTENED_KEYS.includes(e.code)) {
        setterRef.current(false);
        fetchNui("exit");
      }
    };

    window.addEventListener("keyup", keyHandler);

    return () => window.removeEventListener("keyup", keyHandler);
  }, []);
};
