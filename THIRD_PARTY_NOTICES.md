# Third-Party Model Notices

Genie itself is not a machine-learning model and ships none of its own model
weights in this repository. It does, however, build and recommend local
models derived from Alibaba Cloud's Qwen family, each released under the
Apache License, Version 2.0. This file exists so that license and the
required attribution travel with those models wherever Genie packages or
points a user at them (`scripts/models/genie-master.Modelfile`, and the
curated install list in `GenieLocalTinyModelEngine.swift` /
`GeniePremiumTerminalCookbookView.swift`).

## Models

| Genie usage | Upstream model | License | Source |
|---|---|---|---|
| `genie-master` (`FROM qwen3.8:latest`) | Qwen3.8-27B | Apache 2.0 | https://github.com/QwenLM/Qwen3.8 |
| Curated catalog: `qwen3.5:0.8b`, `qwen3.5:2b`, `qwen3.5:4b` | Qwen3.5 | Apache 2.0 | https://github.com/QwenLM/Qwen3.5 |
| Curated catalog: `qwen3-vl:4b` | Qwen3-VL | Apache 2.0 | https://github.com/QwenLM/Qwen3-VL |

`genie-master` is a **derivative work**: the Modelfile sets a custom `SYSTEM`
prompt and generation parameters on top of the unmodified Qwen3.8 weights.
Apache 2.0 §4(b) requires derivative works to carry a prominent notice of
what changed — that notice is the header comment in
`scripts/models/genie-master.Modelfile` itself, which now names the base
model and its license.

Copyright © Alibaba Cloud. Licensed under the Apache License, Version 2.0
(the "License"); you may not use these files except in compliance with the
License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

## Scope note

This covers the models Genie *builds or recommends*. If `scripts/native_image_builder.py`'s
Golden Image work resumes and starts baking a model's weights directly into
the shipped `.raw` disk image (it does not yet — today it only provisions a
bare Ubuntu cloud-init image with no model runtime installed), that image
build step must also copy a full, verbatim copy of the Apache License text
onto the image alongside the weights per §4(a) — a link to this file is not
sufficient for an offline-distributed artifact.

---

## Editor Components: Microsoft Visual Studio Code & Monaco Editor

Genie's built-in **Genio Studio Editor** (`EmbeddedVSCodeStudioView.swift` / `WorkspaceTabType.vsCodeStudio`) incorporates architectural patterns, UI layouts, syntax themes, and open-source components inspired by and derived from Microsoft Visual Studio Code and Monaco Editor.

- **Component**: Visual Studio Code / Monaco Editor
- **Copyright**: Copyright © Microsoft Corporation. All rights reserved.
- **License**: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

