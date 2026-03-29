import { useState, useRef } from "react";
import { motion } from "framer-motion";
import {
  Play,
  Square,
  Music2,
  Leaf,
  Building2,
  Train,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/lib/LanguageContext";

const BASE =
  "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds";

const categories = [
  {
    id: "nature",
    labelKey: "catNature",
    icon: Leaf,
    color: "text-[#10B981]",
    bg: "bg-[#10B981]/10",
    sounds: [
      {
        id: "light-rain",
        labelKey: "sndLightRain",
        emoji: "🌧️",
        src: `${BASE}/rain/light-rain.mp3`,
      },
      {
        id: "heavy-rain",
        labelKey: "sndHeavyRain",
        emoji: "⛈️",
        src: `${BASE}/rain/heavy-rain.mp3`,
      },
      {
        id: "rain-window",
        labelKey: "sndRainWindow",
        emoji: "🪟",
        src: `${BASE}/rain/rain-on-window.mp3`,
      },
      {
        id: "thunder",
        labelKey: "sndThunder",
        emoji: "🌩️",
        src: `${BASE}/rain/thunder.mp3`,
      },
      {
        id: "waves",
        labelKey: "sndWaves",
        emoji: "🌊",
        src: `${BASE}/nature/waves.mp3`,
      },
      {
        id: "river",
        labelKey: "sndRiver",
        emoji: "🏞️",
        src: `${BASE}/nature/river.mp3`,
      },
      {
        id: "waterfall",
        labelKey: "sndWaterfall",
        emoji: "💧",
        src: `${BASE}/nature/waterfall.mp3`,
      },
      {
        id: "campfire",
        labelKey: "sndCampfire",
        emoji: "🔥",
        src: `${BASE}/nature/campfire.mp3`,
      },
      {
        id: "wind-trees",
        labelKey: "sndWindTrees",
        emoji: "🌲",
        src: `${BASE}/nature/wind-in-trees.mp3`,
      },
      {
        id: "howling-wind",
        labelKey: "sndHowlingWind",
        emoji: "🌬️",
        src: `${BASE}/nature/howling-wind.mp3`,
      },
    ],
  },
  {
    id: "things",
    labelKey: "catSoothing",
    icon: Music2,
    color: "text-[#4F46E5]",
    bg: "bg-[#4F46E5]/10",
    sounds: [
      {
        id: "singing-bowl",
        labelKey: "sndSingingBowl",
        emoji: "🔔",
        src: `${BASE}/things/singing-bowl.mp3`,
      },
      {
        id: "wind-chimes",
        labelKey: "sndWindChimes",
        emoji: "🎐",
        src: `${BASE}/things/wind-chimes.mp3`,
      },
      {
        id: "vinyl",
        labelKey: "sndVinyl",
        emoji: "🎵",
        src: `${BASE}/things/vinyl-effect.mp3`,
      },
      {
        id: "clock",
        labelKey: "sndClock",
        emoji: "🕰️",
        src: `${BASE}/things/clock.mp3`,
      },
      {
        id: "keyboard",
        labelKey: "sndKeyboard",
        emoji: "⌨️",
        src: `${BASE}/things/keyboard.mp3`,
      },
    ],
  },
  {
    id: "places",
    labelKey: "catPlaces",
    icon: Building2,
    color: "text-[#F59E0B]",
    bg: "bg-[#F59E0B]/10",
    sounds: [
      {
        id: "cafe",
        labelKey: "sndCafe",
        emoji: "☕",
        src: `${BASE}/places/cafe.mp3`,
      },
      {
        id: "library",
        labelKey: "sndLibrary",
        emoji: "📚",
        src: `${BASE}/places/library.mp3`,
      },
      {
        id: "office",
        labelKey: "sndOffice",
        emoji: "🏢",
        src: `${BASE}/places/office.mp3`,
      },
      {
        id: "restaurant",
        labelKey: "sndRestaurant",
        emoji: "🍽️",
        src: `${BASE}/places/restaurant.mp3`,
      },
      {
        id: "night-village",
        labelKey: "sndNightVillage",
        emoji: "🌙",
        src: `${BASE}/places/night-village.mp3`,
      },
    ],
  },
  {
    id: "transport",
    labelKey: "catTransport",
    icon: Train,
    color: "text-[#60A5FA]",
    bg: "bg-[#60A5FA]/10",
    sounds: [
      {
        id: "airplane",
        labelKey: "sndAirplane",
        emoji: "✈️",
        src: `${BASE}/transport/airplane.mp3`,
      },
      {
        id: "train",
        labelKey: "sndTrain",
        emoji: "🚂",
        src: `${BASE}/transport/inside-a-train.mp3`,
      },
      {
        id: "sailboat",
        labelKey: "sndSailboat",
        emoji: "⛵",
        src: `${BASE}/transport/sailboat.mp3`,
      },
      {
        id: "rowing-boat",
        labelKey: "sndRowingBoat",
        emoji: "🚣",
        src: `${BASE}/transport/rowing-boat.mp3`,
      },
      {
        id: "submarine",
        labelKey: "sndSubmarine",
        emoji: "🌊",
        src: `${BASE}/transport/submarine.mp3`,
      },
    ],
  },
];

export default function RelaxingSounds() {
  const { t } = useLanguage();
  const [playing, setPlaying] = useState(null); // { categoryId, soundId }
  const [loading, setLoading] = useState(null); // soundId being loaded
  const audioRef = useRef(null);

  const handlePlay = (categoryId, sound) => {
    const isSame = playing?.soundId === sound.id;

    // Stop current audio
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.src = "";
      audioRef.current = null;
    }

    if (isSame) {
      setPlaying(null);
      setLoading(null);
      return;
    }

    setLoading(sound.id);
    setPlaying(null);

    const audio = new Audio();
    audio.crossOrigin = "anonymous";
    audio.loop = true;
    audio.src = sound.src;

    audio.addEventListener(
      "canplaythrough",
      () => {
        setLoading(null);
        setPlaying({ categoryId, soundId: sound.id });
      },
      { once: true },
    );

    audio.addEventListener(
      "error",
      () => {
        setLoading(null);
        setPlaying(null);
      },
      { once: true },
    );

    audio.play().catch(() => {
      setLoading(null);
      setPlaying(null);
    });

    audioRef.current = audio;
  };

  const isPlaying = (categoryId, soundId) =>
    playing?.categoryId === categoryId && playing?.soundId === soundId;

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-8"
    >
      {/* Header */}
      <div>
        <h1 className="font-display text-2xl sm:text-3xl font-bold">
          {t("relaxingSoundsTitle")}
        </h1>
        <p className="text-muted-foreground mt-1 text-sm">
          {t("relaxingSoundsSubtitle")}
        </p>
      </div>

      {/* Categories */}
      {categories.map((cat) => {
        const CatIcon = cat.icon;
        return (
          <div key={cat.id}>
            <div className={`flex items-center gap-2 mb-4`}>
              <div
                className={`w-8 h-8 rounded-lg ${cat.bg} flex items-center justify-center`}
              >
                <CatIcon className={`w-4 h-4 ${cat.color}`} />
              </div>
              <h2 className="font-semibold text-base">{t(cat.labelKey)}</h2>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-3">
              {cat.sounds.map((sound) => {
                const active = isPlaying(cat.id, sound.id);
                return (
                  <motion.button
                    key={sound.id}
                    whileTap={{ scale: 0.96 }}
                    onClick={() => handlePlay(cat.id, sound)}
                    className={`rounded-xl border p-4 flex flex-col items-center gap-2 transition-all duration-200 cursor-pointer
                      ${
                        active
                          ? `${cat.bg} border-transparent ring-2 ring-offset-1 ring-current ${cat.color}`
                          : loading === sound.id
                            ? "bg-muted border-border opacity-70"
                            : "bg-card border-border hover:bg-muted"
                      }`}
                  >
                    <span className="text-2xl">{sound.emoji}</span>
                    <span className="text-xs font-medium text-center leading-snug">
                      {t(sound.labelKey)}
                    </span>
                    <div
                      className={`w-6 h-6 rounded-full flex items-center justify-center ${active ? cat.bg : "bg-muted"}`}
                    >
                      {loading === sound.id ? (
                        <Loader2 className="w-3 h-3 text-muted-foreground animate-spin" />
                      ) : active ? (
                        <Square className={`w-3 h-3 ${cat.color}`} />
                      ) : (
                        <Play className="w-3 h-3 text-muted-foreground" />
                      )}
                    </div>
                  </motion.button>
                );
              })}
            </div>
          </div>
        );
      })}

      {/* Stop all */}
      {playing && (
        <div className="flex justify-center pt-2">
          <Button
            variant="outline"
            onClick={() => {
              if (audioRef.current) {
                audioRef.current.pause();
                audioRef.current = null;
              }
              setPlaying(null);
            }}
          >
            <Square className="w-4 h-4 mr-2" />
            {t("stopSound")}
          </Button>
        </div>
      )}
    </motion.div>
  );
}
