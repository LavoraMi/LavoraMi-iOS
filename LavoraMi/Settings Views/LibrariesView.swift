//
//  LibrariesView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/10/2026.
//

import SwiftUI
import MapKit
import SafariServices
import WidgetKit
import LocalAuthentication
import SwiftUIMailView
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseMessaging
import Translation
import StoreKit
import Combine
import SystemConfiguration
import CoreLocation
import FoundationModels

internal import Auth

struct LibrariesView: View {
    let libraries: [LibraryDetailView] = [
        LibraryDetailView(
            name: "abseil",
            version: "1.2025051202.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 The Abseil Authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "AppCheck",
            version: "11.3.2",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2020 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Firebase",
            version: "13.1.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAdsOnDeviceConversion",
            version: "3.7.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleAppMeasurement",
            version: "13.0.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2016 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleDataTransport",
            version: "10.1.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleMobileAds",
            version: "13.11.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleUserMessagingPlatform",
            version: "3.1.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GoogleUtilities",
            version: "8.1.5",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2017 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "gRPC",
            version: "1.83.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2015 gRPC authors",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "GTMSessionFetcher",
            version: "5.3.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2014 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "InteropForGoogle",
            version: "101.0.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "leveldb",
            version: "1.22.5",
            license: "BSD 3-Clause License",
            copyright: "Copyright (c) 2011 The LevelDB Authors",
            licenseText: """
            Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

            1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
            2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
            3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
            """
        ),
        LibraryDetailView(
            name: "nanopb",
            version: "2.30910.1",
            license: "Zlib License",
            copyright: "Copyright (c) 2011 Petteri Aimonen",
            licenseText: """
            This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

            Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

            1. The origin of this software must not be misrepresented.
            2. Altered source versions must be plainly marked as such.
            3. This notice may not be removed or altered from any source distribution.
            """
        ),
        LibraryDetailView(
            name: "Promises",
            version: "2.4.1",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2018 Google LLC",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "Supabase",
            version: "2.55.4",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Supabase",
            licenseText: """
            MIT License

            Copyright (c) 2021 Supabase

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-asn1",
            version: "1.7.3",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2022 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-issue-reporting",
            version: "2.1.2",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2022 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-clocks",
            version: "1.1.1",
            license: "MIT License",
            copyright: "Copyright (c) 2022 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2022 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-concurrency-extras",
            version: "1.4.3",
            license: "MIT License",
            copyright: "Copyright (c) 2023 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2023 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView(
            name: "swift-crypto",
            version: "4.5.2",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2019 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "swift-http-types",
            version: "1.8.0",
            license: "Apache License 2.0",
            copyright: "Copyright (c) 2023 Apple Inc.",
            licenseText: """
            Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            """
        ),
        LibraryDetailView(
            name: "SwiftUIMailView",
            version: "1.0.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Gordan Glavaš",
            licenseText: """
            MIT License

            Copyright (c) 2021 Gordan Glavaš

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        ),
        LibraryDetailView (
            name: "xctest-dynamic-overlay",
            version: "1.13.1",
            license: "MIT License",
            copyright: "Copyright (c) 2021 Point-Free, Inc.",
            licenseText: """
            MIT License

            Copyright (c) 2021 Point-Free, Inc.

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
            """
        )
    ]
    
    var body: some View {
        List {
            ForEach(libraries, id: \.name) { library in
                NavigationLink(destination: LibraryDetailView(
                    name: library.name,
                    version: library.version,
                    license: library.license,
                    copyright: library.copyright,
                    licenseText: library.licenseText
                )) {
                    LibraryRowView(
                        name: library.name,
                        version: library.version,
                        license: library.license,
                        copyright: library.copyright
                    )
                }
            }
        }
        .navigationTitle("Librerie Open-Source")
    }
}
