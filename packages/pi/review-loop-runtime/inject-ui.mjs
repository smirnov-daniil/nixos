import { readFile, writeFile } from "node:fs/promises";

const file = process.argv[2];
if (!file) throw new Error("Usage: inject-ui.mjs <index.html>");

const marker = "data-flake-review-loop";
const html = await readFile(file, "utf8");
if (html.includes(marker)) process.exit(0);

const injected = `<style ${marker}>#flake-review-loop-close{width:28px;height:28px;padding:0}</style>
<script ${marker}>
(() => {
  const toolbar = document.querySelector(".toolbar");
  const close = document.createElement("button");
  close.id = "flake-review-loop-close";
  close.className = "icon-button";
  close.type = "button";
  close.title = "Close Review Loop";
  close.setAttribute("aria-label", "Close Review Loop");
  close.textContent = "×";
  close.addEventListener("click", () => window.glimpse?.close());
  toolbar?.append(close);
  const receive = window.__reviewReceive;
  window.__reviewReceive = (message) => {
    receive.call(window, message);
    if (message?.type === "workspace" && message.state?.baseLabel) {
      const head = document.getElementById("mode-head");
      if (head) head.textContent = "vs " + message.state.baseLabel;
    }
  };
})();
</script>`;

if (!html.includes("</body>")) throw new Error("Review Loop HTML has no body terminator");
await writeFile(file, html.replace("</body>", `${injected}\n</body>`), "utf8");
