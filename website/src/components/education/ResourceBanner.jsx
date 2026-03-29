import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import { ChevronRight, Download } from "lucide-react";
import { useLanguage } from "@/lib/LanguageContext";

export default function ResourceBanner({ resource, index }) {
  const { t } = useLanguage();
  const isClickable = resource.link || resource.externalLink;
  const Wrapper = resource.link ? Link : resource.externalLink ? "a" : "div";
  const wrapperProps = resource.link
    ? { to: resource.link }
    : resource.externalLink
      ? {
          href: resource.externalLink,
          target: "_blank",
          rel: "noopener noreferrer",
        }
      : {};

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.08 }}
    >
      <Wrapper
        {...wrapperProps}
        className={`rounded-2xl border bg-gradient-to-br ${resource.color} ${resource.border} p-6 flex items-start gap-4 ${isClickable ? "hover:shadow-md hover:border-teal-300 transition-all cursor-pointer" : ""}`}
      >
        <div
          className={`w-12 h-12 rounded-xl ${resource.iconBg} flex items-center justify-center text-2xl shrink-0`}
        >
          {resource.icon}
        </div>
        <div className="flex-1 min-w-0">
          <h2 className="font-semibold text-base text-foreground leading-snug mb-1.5">
            {resource.title}
          </h2>
          <p
            className="text-sm text-muted-foreground leading-relaxed"
            dangerouslySetInnerHTML={{
              __html: resource.description.replace(
                "World Health Organization",
                "<strong>World Health Organization</strong>",
              ),
            }}
          />
          {resource.downloadNepali && (
            <a
              href={resource.downloadNepali}
              target="_blank"
              rel="noopener noreferrer"
              onClick={(e) => e.stopPropagation()}
              className="inline-flex items-center gap-1.5 mt-3 px-3 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-xs font-medium transition-colors"
            >
              <Download className="w-3.5 h-3.5" />
              {t("downloadInNepali")}
            </a>
          )}
        </div>
        {isClickable && (
          <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0 mt-1" />
        )}
      </Wrapper>
    </motion.div>
  );
}
