import React, { useState, useRef, useEffect } from 'react';
import CodeBlock from '@theme/CodeBlock';
import styles from './CollapsibleCode.module.css';

type Props = {
  /**
   * Optional path to a static file to display as a code block.
   * The file must be imported with the `?raw` query in your MDX file:
   *
   * ```mdx
   * import scriptContent from '!!raw-loader!./Scripts/MyScript.ps1';
   *
   * <CollapsibleCode filePath={scriptContent} language="powershell" title="MyScript.ps1" maxLines={10} />
   * ```
   *
   * When `filePath` is provided, `children` is ignored and the file content
   * is rendered with the given `language` and `title`.
   *
   * When `filePath` is omitted, pass a Docusaurus fenced code block as a child:
   *
   * ```mdx
   * <CollapsibleCode maxLines={10}>
   *
   * ```powershell title="script.ps1"
   * Write-Host "`n Hello"   # backticks are fine!
   * ```
   *
   * </CollapsibleCode>
   * ```
   */
  children?: React.ReactNode;
  /** Raw file content (use `import content from '!!raw-loader!./file?raw'` or webpack asset/source) */
  fileContent?: string;
  /** Language for syntax highlighting when using `fileContent` (e.g. "powershell", "csharp") */
  language?: string;
  /** Title shown in the code block header when using `fileContent` */
  title?: string;
  /** Approximate number of code lines visible before "Show more" (default: 15) */
  maxLines?: number;
};

/** Approximate rendered height per line of code in Docusaurus's theme (px) */
const LINE_HEIGHT_PX = 24;
/** Approximate vertical padding inside a Docusaurus code block (px) */
const BLOCK_PADDING_PX = 40;

export default function CollapsibleCode({ children, fileContent, language, title, maxLines = 15 }: Props) {
  const [expanded, setExpanded] = useState(false);
  const [isCollapsible, setIsCollapsible] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const collapsedHeight = maxLines * LINE_HEIGHT_PX + BLOCK_PADDING_PX;

  useEffect(() => {
    if (containerRef.current) {
      setIsCollapsible(containerRef.current.scrollHeight > collapsedHeight + 10);
    }
  }, [collapsedHeight]);

  const handleToggle = () => {
    const wasExpanded = expanded;
    setExpanded(e => !e);

    // When collapsing: scroll the top of the wrapper back into view
    if (wasExpanded && wrapperRef.current) {
      // Wait one frame for the DOM to shrink before scrolling
      requestAnimationFrame(() => {
        wrapperRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    }
  };

  return (
    <div ref={wrapperRef} className={styles.wrapper}>
      {/* ── Code area (height-constrained when collapsed) ─────────── */}
      <div
        ref={containerRef}
        className={styles.content}
        style={{ maxHeight: expanded ? undefined : `${collapsedHeight}px` }}
      >
        {fileContent !== undefined
          ? <CodeBlock language={language} title={title}>{fileContent}</CodeBlock>
          : children}
        {isCollapsible && !expanded && <div className={styles.fadeOverlay} />}
      </div>

      {/* ── Expand / collapse button ──────────────────────────────── */}
      {isCollapsible && (
        <div className={styles.toggleRow}>
          <button
            className={styles.toggleBtn}
            onClick={handleToggle}
          >
            {expanded ? '▲ Show less' : '▼ Show more'}
          </button>
        </div>
      )}
    </div>
  );
}
