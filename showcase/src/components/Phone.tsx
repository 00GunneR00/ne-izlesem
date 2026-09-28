import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";

// Device captures are 1080x2340; the top 90px is the Android status bar, which we crop.
const SOURCE_W = 1080;
const SOURCE_H = 2340;
const STATUS_BAR = 90;

type Media =
  | { image: string }
  | { video: string; trimBefore?: number; playbackRate?: number };

export const Phone: React.FC<
  Media & { height: number; style?: React.CSSProperties }
> = (props) => {
  const { height, style } = props;
  const bezel = Math.round(height * 0.016);
  const screenH = height - bezel * 2;
  const scale = screenH / (SOURCE_H - STATUS_BAR);
  const screenW = Math.round(SOURCE_W * scale);
  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left: 0,
    top: -STATUS_BAR * scale,
    width: screenW,
    height: SOURCE_H * scale,
  };

  return (
    <div
      style={{
        width: screenW + bezel * 2,
        height,
        padding: bezel,
        borderRadius: height * 0.06,
        background: "linear-gradient(145deg, #2a2222, #121010)",
        boxShadow:
          "0 40px 90px rgba(0,0,0,0.65), 0 0 0 2px #3a2c2c, 0 0 120px rgba(211,47,47,0.18)",
        boxSizing: "border-box",
        ...style,
      }}
    >
      <div
        style={{
          position: "relative",
          width: screenW,
          height: screenH,
          borderRadius: height * 0.047,
          overflow: "hidden",
          background: "#000",
        }}
      >
        {"image" in props ? (
          <Img src={staticFile(props.image)} style={mediaStyle} />
        ) : (
          <OffthreadVideo
            src={staticFile(props.video)}
            trimBefore={props.trimBefore}
            playbackRate={props.playbackRate}
            muted
            style={mediaStyle}
          />
        )}
      </div>
    </div>
  );
};
