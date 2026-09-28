import { loadFont as loadMontserrat } from "@remotion/google-fonts/Montserrat";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";

// Palette sampled from the app's own screens.
export const colors = {
  bg: "#0A0808",
  surface: "#1E1414",
  surfaceBorder: "#2E2020",
  primary: "#D32F2F",
  title: "#F4B6A8",
  text: "#F3E6E3",
  muted: "#B9A5A1",
};

export const { fontFamily: headingFont } = loadMontserrat("normal", {
  weights: ["600", "800"],
  subsets: ["latin", "latin-ext"],
});

export const { fontFamily: bodyFont } = loadInter("normal", {
  weights: ["400", "500", "600"],
  subsets: ["latin", "latin-ext"],
});

export const FPS = 30;
export const TRANSITION = 15;
