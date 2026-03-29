import { motion } from "framer-motion";
import { BookOpen } from "lucide-react";
import ResourceBanner from "@/components/education/ResourceBanner";
import { useLanguage } from "@/lib/LanguageContext";

export default function Education() {
  const { t } = useLanguage();

  const resources = [
    {
      id: 1,
      title: t("eduRes1Title"),
      description: t("eduRes1Desc"),
      icon: "🎙️",
      color:
        "from-violet-50 to-indigo-50 dark:from-violet-950 dark:to-indigo-950",
      border: "border-violet-200 dark:border-violet-800",
      iconBg: "bg-violet-100 dark:bg-violet-900",
      link: "/education/radio-program",
    },
    {
      id: 2,
      title: t("eduRes2Title"),
      description: t("eduRes2Desc"),
      icon: "🧘",
      color: "from-teal-50 to-green-50 dark:from-teal-950 dark:to-green-950",
      border: "border-teal-200 dark:border-teal-800",
      iconBg: "bg-teal-100 dark:bg-teal-900",
      externalLink: "https://www.who.int/publications/i/item/9789240003927",
      downloadNepali:
        "https://iris.who.int/bitstream/handle/10665/331901/9789240003910-nep.pdf",
    },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-8 max-w-2xl mx-auto"
    >
      {/* Header */}
      <div>
        <div className="flex items-center gap-3 mb-1">
          <div className="w-10 h-10 rounded-xl bg-violet-100 dark:bg-violet-900 flex items-center justify-center">
            <BookOpen className="w-5 h-5 text-violet-600 dark:text-violet-400" />
          </div>
          <h1 className="font-display text-2xl sm:text-3xl font-bold">
            {t("educationTitle")}
          </h1>
        </div>
        <p className="text-muted-foreground text-sm mt-1 ml-13">
          {t("educationDesc")}
        </p>
      </div>

      {/* Resources */}
      <div className="space-y-4">
        {resources.map((resource, i) => (
          <ResourceBanner key={resource.id} resource={resource} index={i} />
        ))}
      </div>
    </motion.div>
  );
}
