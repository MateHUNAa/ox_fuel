import { MutableRefObject, useEffect, useRef } from "react";
import { noop } from "@/utils/misc";

interface NuiMessageData<T = unknown> {
  action: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;

export const useNuiEvent = <T = any>(
  action: string,
  handler: (data: T) => void
) => {
  const saveHandler: MutableRefObject<NuiHandlerSignature<T>> = useRef(noop);

  //   Set mutableObj on Change
  useEffect(() => {
    saveHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent<NuiMessageData<T>>) => {
      const { action: eventAction, data } = event.data;

      if (saveHandler.current) {
        if (eventAction === action) {
          saveHandler.current(data);
        }
      }
    };

    window.addEventListener("message", eventListener);

    return () => window.removeEventListener("message", eventListener);
  }, [action]);
};

export default useNuiEvent;
