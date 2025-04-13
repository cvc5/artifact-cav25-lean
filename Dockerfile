# Define a build argument for the number of threads
ARG THREADS=8

# Use Ubuntu 24.04 as the base image with x86 architecture
FROM --platform=linux/amd64 ubuntu:24.04

# Set up non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Update package list and install development tools
# TODO: remove htop and bubblewrap if not needed
RUN apt-get update && \
    apt-get install -y bison bubblewrap bzip2 cmake curl flex gcc g++ git htop libgmp-dev make mercurial python3 python3-pip python3.12-venv sudo unzip zstd && \
    apt-get clean

# Create a new user named 'user' with no password and switch to it
RUN useradd -m -s /bin/bash user && \
    adduser user sudo && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER user

# Create the artifact directory and set it as the working directory
RUN mkdir -p /home/user/artifact
WORKDIR /home/user/artifact

# Download and unzip Seventeen Provers baseline benchmarks
RUN mkdir -p /home/user/artifact/benchmarks/seventeen
RUN curl -L -o baseline_probs.zip https://zenodo.org/records/6394938/files/baseline_probs.zip?download=1
RUN unzip baseline_probs.zip -d /home/user/artifact/benchmarks/seventeen
RUN rm baseline_probs.zip

# Download and unzip SMT-LIB benchmarks for supported theories: (QF_)?(UF|(UF)?(IDL|RDL|IRDL|LIA|LRA|LIRA))
RUN mkdir -p /home/user/artifact/benchmarks/SMT-LIB
RUN curl -L -o UF.tar.zst https://zenodo.org/records/11061097/files/UF.tar.zst?download=1 && \
    tar -xf UF.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm UF.tar.zst
RUN curl -L -o LIA.tar.zst https://zenodo.org/records/11061097/files/LIA.tar.zst?download=1 && \
    tar -xf LIA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm LIA.tar.zst
RUN curl -L -o LRA.tar.zst https://zenodo.org/records/11061097/files/LRA.tar.zst?download=1 && \
    tar -xf LRA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm LRA.tar.zst
RUN curl -L -o UFIDL.tar.zst https://zenodo.org/records/11061097/files/UFIDL.tar.zst?download=1 && \
    tar -xf UFIDL.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm UFIDL.tar.zst
RUN curl -L -o UFLIA.tar.zst https://zenodo.org/records/11061097/files/UFLIA.tar.zst?download=1 && \
    tar -xf UFLIA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm UFLIA.tar.zst
RUN curl -L -o UFLRA.tar.zst https://zenodo.org/records/11061097/files/UFLRA.tar.zst?download=1 && \
    tar -xf UFLRA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm UFLRA.tar.zst
RUN curl -L -o QF_UF.tar.zst https://zenodo.org/records/11061097/files/QF_UF.tar.zst?download=1 && \
    tar -xf QF_UF.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_UF.tar.zst
RUN curl -L -o QF_IDL.tar.zst https://zenodo.org/records/11061097/files/QF_IDL.tar.zst?download=1 && \
    tar -xf QF_IDL.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_IDL.tar.zst
RUN curl -L -o QF_RDL.tar.zst https://zenodo.org/records/11061097/files/QF_RDL.tar.zst?download=1 && \
    tar -xf QF_RDL.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_RDL.tar.zst
RUN curl -L -o QF_LIA.tar.zst https://zenodo.org/records/11061097/files/QF_LIA.tar.zst?download=1 && \
    tar -xf QF_LIA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_LIA.tar.zst
RUN curl -L -o QF_LRA.tar.zst https://zenodo.org/records/11061097/files/QF_LRA.tar.zst?download=1 && \
    tar -xf QF_LRA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_LRA.tar.zst
RUN curl -L -o QF_LIRA.tar.zst https://zenodo.org/records/11061097/files/QF_LIRA.tar.zst?download=1 && \
    tar -xf QF_LIRA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_LIRA.tar.zst
RUN curl -L -o QF_UFIDL.tar.zst https://zenodo.org/records/11061097/files/QF_UFIDL.tar.zst?download=1 && \
    tar -xf QF_UFIDL.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_UFIDL.tar.zst
RUN curl -L -o QF_UFLIA.tar.zst https://zenodo.org/records/11061097/files/QF_UFLIA.tar.zst?download=1 && \
    tar -xf QF_UFLIA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_UFLIA.tar.zst
RUN curl -L -o QF_UFLRA.tar.zst https://zenodo.org/records/11061097/files/QF_UFLRA.tar.zst?download=1 && \
    tar -xf QF_UFLRA.tar.zst -C /home/user/artifact/benchmarks/SMT-LIB && \
    rm QF_UFLRA.tar.zst

# Install elan and update environment
RUN curl https://elan.lean-lang.org/elan-init.sh -sSf | sh -s -- -y --default-toolchain none
ENV PATH="/home/user/.elan/bin:$PATH"

# Install opam and initialize it without a default switch
RUN yes "/usr/local/bin" | bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)" && \
    opam init --disable-sandboxing --bare

# Clone and build cvc5 and ethos
RUN git clone https://github.com/cvc5/cvc5 && \
    cd cvc5 && \
    git checkout 8cfac8f956c4ef1543f52eb2d862d81367b3d3ed && \
    ./configure.sh production --static --auto-download && \
    cd build && make
RUN cd /home/user/artifact/cvc5 && \
    contrib/get-ethos-checker
COPY cvc5+ethos.sh /home/user/artifact/cvc5+ethos.sh

# Clone and build duper
RUN git clone https://github.com/leanprover-community/duper && \
    cd duper && \
    git checkout v0.0.22 && \
    lake update && \
    lake build
COPY duper.sh /home/user/artifact/duper.sh

# Clone and build cpc-checker
RUN git clone https://github.com/abdoo8080/lean-cpc-checker && \
    cd lean-cpc-checker && \
    git checkout 2b00b3061b99f60ec5eca0cf994bfb9d95d19a86 && \
    lake update && \
    lake build

# Clone and build Isabelle and AFP
RUN hg clone https://isabelle.in.tum.de/repos/isabelle && \
    cd isabelle && \
    hg update b87fcf474e7f
RUN isabelle/Admin/init
    isabelle/bin/isabelle build -b HOL
RUN hg clone https://foss.heptapod.net/isa-afp/afp-devel && \
    cd afp-devel && \
    hg update e2ae9549a7b0
ENV AFP="/home/user/artifact/afp-devel/thys"
ENV PATH="/home/user/artifact/isabelle/bin:$PATH"

# Clone and build smtcoq 
RUN opam switch create ocaml-base-compiler.4.11.1
RUN opam install -y --confirm-level=unsafe-yes num coq.8.19.2
RUN git clone https://github.com/smtcoq/smtcoq && \
    cd smtcoq/src && \
    git checkout coq-8.19 && \
    eval $(opam env) && \
    make && make install && \
    cd extraction && make

# Download and build veriT
RUN curl -L -o veriT9f48a98.tar.gz https://www.lri.fr/~keller/Documents-recherche/Smtcoq/veriT9f48a98.tar.gz && \
    tar -xf veriT9f48a98.tar.gz -C /home/user/artifact && \
    rm veriT9f48a98.tar.gz
RUN cd /home/user/artifact/veriT9f48a98 && \
    ./configure && make
COPY verit+smtcoq.sh /home/user/artifact/verit+smtcoq.sh

# Set the default command to run htop
CMD ["bash"]
