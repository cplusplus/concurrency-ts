<!--
1) executor class is defines in std::experimental

-->

# General # general # general

## Scope # general.scope # general.scope

This Technical Specification describes requirements for the implementation of a
number of concurrency extensions that can be used in computer programs written
in the C++ programming language. The extensions described by this Technical
Specification are realizable across a broad class of computer architectures.

This Technical Specification is non-normative. Some of the functionality
described by this Technical Specification may be considered for standardization
in a future version of C++, but it is not currently part of any C++ standard.
Some of the functionality in this Technical Specification may never be
standardized, and other functionality may be standardized in a substantially
changed form.

The goal of this Technical Specification is to enhance the existing practice for
concurrency in the C++ standard algorithms library. It gives advice on
extensions to those vendors who wish to provide them.

## Normative references # general.references # general.references

The following reference document is indepensible for the application of this
document. For dated references, only the edition cited applies. For undated
references, the latest edition of the referenced document (including any
amendments) applies.

* ISO/IEC 14882:2011, Programming Languages -- C++

ISO/IEC 14882:2011 is herein called the C++ Standard. The library described in
ISO/IEC 14882:2011 clauses 17-30 is herein called the C++ Standard Library. 

Unless otherwise specified, the whole of the C++ Standard Library introduction
[lib.library] is included into this Technical Specification by reference.

## Namespaces and headers # general.namespaces # general.namespaces

Some of the extensions described in this Technical Specification represent types
and functions that are currently not part of the C++ Standards Library, and
because these extensions are experimental, they should not be declared directly
within namespace `std`. Instead, such extensions are declared in namespace
`std::experimental`.

[*Note:* Once standardized, these components are expected to be promoted to
namespace `std`. -- *end note*]

Unless otherwise specified, references to such entities described in this
Technical Specification are assumed to be qualified with
`std::experimental`, and references to entities described in the
C++ Standard Library are assumed to be qualified with `std::`.

## Terms and definitions # general.defns # general.defns

For the purposes of this document, the terms and definitions given in the C++
Standard and the following apply.

\newpage
