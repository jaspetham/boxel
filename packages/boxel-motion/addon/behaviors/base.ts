import { Value } from '../value';

export const FPS = 60 / 1000; // 60 FPS
export function timeToFrame(time: number): number {
  return Math.round(time * FPS);
}

export type EasingToFramesArgument = {
  from: number;
  to: number;
  duration: number;
  delay?: number;
};

export type SpringToFramesArgument = {
  from: number;
  to: number;
  velocity?: number;
  delay?: number;
};

export type StaticToFramesArgument = {
  value: Value;
  duration: number;
};

export type WaitToFramesArgument = {
  duration: number;
};

export type Frame = {
  value: number;
  velocity: number; // units per second
};

export type FrameGenerator = Generator<Frame | void, void, never>;

export default interface Behavior {
  /**
   * Calculates the frames for the given parameters.
   *
   * @param options
   */
  getFrames(
    options:
      | EasingToFramesArgument
      | SpringToFramesArgument
      | StaticToFramesArgument
      | WaitToFramesArgument
  ): FrameGenerator;
}

export interface EasingBehavior extends Behavior {
  /**
   * Calculates (an approximation of) the instantaneous velocity in units per second at the given time.
   *
   * @param time
   * @param duration
   * @param frames
   */
  instantaneousVelocity(
    time: number,
    duration: number,
    frames: number[]
  ): number;
}
