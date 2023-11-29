# Copyright 2021-2023 Buf Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Defines buf_push rule"""

load("@rules_proto//proto:defs.bzl", "ProtoInfo")
load(":module.bzl", "create_module_zip")

_DOC = """
`buf_push` pushes one or more `proto_library` targets to the [BSR](https://docs.buf.build/bsr/introduction).

For more info please refer to the [`buf_push` section](https://docs.buf.build/build-systems/bazel#buf-push) of the docs.
"""

_TOOLCHAIN = str(Label("//tools/buf:toolchain_type"))

def _buf_push_impl(ctx):
    proto_infos = [t[ProtoInfo] for t in ctx.attr.targets]
    zip_file = ctx.actions.declare_file("{}.zip".format(ctx.label.name))
    create_module_zip(
        ctx,
        ctx.executable._zipper,
        proto_infos,
        ctx.file.config,
        ctx.file.lock,
        zip_file,
    )
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "{} push {}".format(ctx.toolchains[_TOOLCHAIN].cli.short_path, zip_file.short_path),
        is_executable = True,
    )
    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = [zip_file, ctx.toolchains[_TOOLCHAIN].cli],
            ),
        ),
    ]

buf_push = rule(
    implementation = _buf_push_impl,
    doc = _DOC,
    attrs = {
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            executable = True,
            cfg = "exec",
        ),
        "targets": attr.label_list(
            providers = [ProtoInfo],
            mandatory = True,
            doc = """`proto_library` targets that should be pushed. 
            Only the direct source will be pushed i.e. only the files in the `srcs` attribute of `proto_library` targets will
            be pushed, the files from the `deps` attribute will not be pushed.
            """,
        ),
        "config": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The `buf.yaml` file",
        ),
        "lock": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The `buf.lock` file",
        ),
    },
    toolchains = [_TOOLCHAIN],
    executable = True,
)
