// bin/copy-ilabels.cc

// Copyright 2009-2011  Microsoft Corporation

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.

#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "matrix/kaldi-vector.h"
#include "transform/transform-common.h"


int main(int argc, char *argv[]) {
  try {
    using namespace kaldi;

    const char *usage =
        "Copy ilabel files from text to binary\n"
        "(e.g. alignments)\n"
        "\n"
        "Usage: copy-ilabels [options] (ilabel-in-rspecifier) (ilabel-out-wxfilename)\n"
        " e.g.: copy-ilabels --binary=false foo -\n";
    
    bool binary = true;
    ParseOptions po(usage);

    po.Register("binary", &binary, "Write in binary mode (only relevant if output is a wxfilename)");

    po.Read(argc, argv);

    if (po.NumArgs() != 2) {
      po.PrintUsage();
      exit(1);
    }

    std::string ilabels_in_fn = po.GetArg(1),
        ilabels_out_fn = po.GetArg(2);

	std::vector<std::vector<int32> > ilabel_info;

    SequentialInt32VectorVectorReader reader(in_fn);
      
	WriteILabelInfo(Output(ilabels_out_fn, binary).Stream(), binary, reader.Value());

	KALDI_LOG << "Copied ilabel file, in binary format, to " << ilabels_out_fn;
	return 0;
  } catch(const std::exception &e) {
    std::cerr << e.what();
    return -1;
  }
}


