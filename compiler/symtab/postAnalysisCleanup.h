#ifndef _POST_ANALYSIS_CLEANUP_H_
#define _POST_ANALYSIS_CLEANUP_H_

#include "symtabTraversal.h"

class PostAnalysisCleanup : public SymtabTraversal {
 public:
  PostAnalysisCleanup::PostAnalysisCleanup();
  void processSymbol(Symbol* sym);
};

#endif
