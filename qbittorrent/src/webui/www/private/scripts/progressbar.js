/*
 * Bittorrent Client using Qt and libtorrent.
 * Copyright (C) 2008  Christophe Dumez <chris@qbittorrent.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * In addition, as a special exception, the copyright holders give permission to
 * link this program with the OpenSSL project's "OpenSSL" library (or with
 * modified versions of it that use the same license as the "OpenSSL" library),
 * and distribute the linked executables. You must obey the GNU General Public
 * License in all respects for all of the code used other than "OpenSSL".  If you
 * modify file(s), you may extend this exception to your version of the file(s),
 * but you are not obligated to do so. If you do not wish to do so, delete this
 * exception statement from your version.
 */

"use strict";

window.qBittorrent ??= {};
window.qBittorrent.ProgressBar ??= (() => {
    const exports = () => {
        return {
            ProgressBar: ProgressBar
        };
    };

    class ProgressBar extends HTMLElement {
        static #progressBarUniqueId = 0;

        #value = 0;

        #id = ++ProgressBar.#progressBarUniqueId;

        #track = document.createElement("div");
        #fill = document.createElement("div");
        #label = document.createElement("span");

        constructor(value) {
            super();

            // A thin bar with the percentage beside it, so the text never sits on the fill.
            // Colors come from custom properties, which the page stylesheet can override.
            this.#track.style.flex = "1 1 auto";
            this.#track.style.minWidth = "16px";
            this.#track.style.height = "var(--progress-bar-height, 5px)";
            this.#track.style.borderRadius = "var(--progress-bar-height, 5px)";
            this.#track.style.background = "var(--progress-bar-track, var(--color-border-default))";
            this.#track.style.overflow = "hidden";

            this.#fill.style.height = "100%";
            this.#fill.style.background = "var(--progress-bar-fill, var(--color-background-blue))";

            this.#label.style.flex = "0 0 auto";
            this.#label.style.minWidth = "5.6ch";
            this.#label.style.textAlign = "right";
            this.#label.style.fontVariantNumeric = "tabular-nums";
            this.#label.style.color = "var(--progress-bar-text, inherit)";

            this.#track.appendChild(this.#fill);

            this.attachShadow({ mode: "open" });
            this.shadowRoot.host.id = this.#id;
            this.shadowRoot.host.style.display = "flex";
            this.shadowRoot.host.style.alignItems = "center";
            this.shadowRoot.host.style.gap = "6px";
            this.shadowRoot.host.style.minWidth = "0";
            this.shadowRoot.appendChild(this.#track);
            this.shadowRoot.appendChild(this.#label);

            this.setValue(value);
        }

        getValue() {
            return this.#value;
        }

        setValue(value) {
            value = Number(value);
            if (Number.isNaN(value))
                value = 0;
            this.#value = Math.min(Math.max(value, 0), 100);

            this.#label.textContent = `${window.qBittorrent.Misc.toFixedPointString(this.#value, 1)}%`;
            this.#fill.style.width = `${this.#value}%`;
        }
    }

    customElements.define("progress-bar", ProgressBar);

    return exports();
})();
Object.freeze(window.qBittorrent.ProgressBar);
