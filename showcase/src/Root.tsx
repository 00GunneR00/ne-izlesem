import React from "react";
import { Composition, Folder } from "remotion";
import { Showcase, totalDuration } from "./Showcase";
import { Reel, reelDuration } from "./reels/Reel";
import { reels } from "./reels/reels";
import { FPS } from "./theme";

export const Root: React.FC = () => (
  <>
    <Composition
      id="Showcase"
      component={Showcase}
      durationInFrames={totalDuration}
      fps={FPS}
      width={1920}
      height={1080}
    />
    <Folder name="Reels">
      {reels.map((spec) => (
        <Composition
          key={spec.id}
          id={spec.id}
          component={Reel}
          defaultProps={{ spec }}
          durationInFrames={reelDuration(spec)}
          fps={FPS}
          width={1080}
          height={1920}
        />
      ))}
    </Folder>
  </>
);
