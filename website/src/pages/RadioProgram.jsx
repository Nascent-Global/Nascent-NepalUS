import { motion } from "framer-motion";
import { ArrowLeft, Radio } from "lucide-react";
import { Link } from "react-router-dom";
import { useLanguage } from "@/lib/LanguageContext";

const episodeKeys = [
  {
    number: 1,
    titleKey: "ep1Title",
    url: "https://youtu.be/VB0yLU9Copc?si=fpJ5khdHlhNQTrPY",
  },
  {
    number: 2,
    titleKey: "ep2Title",
    url: "https://youtu.be/1GFY4G9Aiaw?si=riiivJR0lcmKhUXK",
  },
  {
    number: 3,
    titleKey: "ep3Title",
    url: "https://youtu.be/DJ_qPPkSebc?si=mf0vOxbuINPtoga2",
  },
  {
    number: 4,
    titleKey: "ep4Title",
    url: "https://youtu.be/zmU-RFZoN_M?si=EbpwouNOdF07X2nn",
  },
  {
    number: 5,
    titleKey: "ep5Title",
    url: "https://youtu.be/f3pliki45NY?si=cBibDml5Gfod0v2O",
  },
  {
    number: 6,
    titleKey: "ep6Title",
    url: "https://youtu.be/F6gUfQp3nwo?si=xyjI5XTHHkNHvCI1",
  },
  {
    number: 7,
    titleKey: "ep7Title",
    url: "https://youtu.be/yCFN_wIuraY?si=GYCtiLE_XBb0Lc1Q",
  },
  {
    number: 8,
    titleKey: "ep8Title",
    url: "https://youtu.be/m0f1Jpr31lE?si=qC794JqQ79dNbH9y",
  },
  {
    number: 9,
    titleKey: "ep9Title",
    url: "https://youtu.be/KlIvWtzUAb0?si=UxqvqWYPCQjecyrc",
  },
  {
    number: 10,
    titleKey: "ep10Title",
    url: "https://youtu.be/ukf2uoNetcM?si=Jd0NqPi3d2EkhBOM",
  },
];

function getYouTubeId(url) {
  const match = url.match(/youtu\.be\/([^?]+)/);
  return match ? match[1] : null;
}

export default function RadioProgram() {
  const { t } = useLanguage();
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-8 max-w-2xl mx-auto"
    >
      {/* Back */}
      <Link
        to="/education"
        className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        {t("backToEducation")}
      </Link>

      {/* Header */}
      <div>
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 rounded-xl bg-violet-100 flex items-center justify-center">
            <Radio className="w-5 h-5 text-violet-600" />
          </div>
          <h1 className="font-display text-2xl sm:text-3xl font-bold">
            {t("manoSambaad")}
          </h1>
        </div>
        <p className="text-xs font-semibold uppercase tracking-widest text-violet-500 mb-3">
          {t("niomhSeries")}
        </p>
        <p
          className="text-sm text-muted-foreground leading-relaxed"
          dangerouslySetInnerHTML={{ __html: t("radioProgramDesc") }}
        />
      </div>

      {/* Episodes */}
      <div className="space-y-4">
        <h2 className="text-base font-semibold">{t("episodes")}</h2>
        {episodeKeys.map((ep, i) => {
          const videoId = getYouTubeId(ep.url);
          const thumbnail = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;
          return (
            <motion.a
              key={ep.number}
              href={ep.url}
              target="_blank"
              rel="noopener noreferrer"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="flex items-center gap-4 rounded-xl border border-border bg-card p-3 hover:shadow-md hover:border-violet-200 transition-all group"
            >
              {/* Thumbnail */}
              <div className="relative w-24 h-16 rounded-lg overflow-hidden shrink-0 bg-muted">
                <img
                  src={thumbnail}
                  alt={ep.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 flex items-center justify-center bg-black/30 group-hover:bg-black/20 transition-colors">
                  <div className="w-7 h-7 rounded-full bg-white/90 flex items-center justify-center">
                    <svg
                      className="w-3 h-3 text-violet-600 ml-0.5"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                    >
                      <path d="M8 5v14l11-7z" />
                    </svg>
                  </div>
                </div>
              </div>

              {/* Info */}
              <div className="flex-1 min-w-0">
                <span className="text-xs text-violet-500 font-semibold">
                  {t("episode")} {ep.number}
                </span>
                <p className="text-sm font-medium text-foreground leading-snug mt-0.5 truncate">
                  {t(ep.titleKey)}
                </p>
              </div>
            </motion.a>
          );
        })}
      </div>
    </motion.div>
  );
}
