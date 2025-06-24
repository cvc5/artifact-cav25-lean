# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set up non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Update package list and install development tools
RUN apt-get update && \
    apt-get install -y bison bzip2 cmake curl flex gcc g++ git htop libgmp-dev make mercurial python3 python3-pip python3.12-venv sudo unzip zstd && \
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
RUN curl -L -o baseline_probs.zip https://zenodo.org/records/6394938/files/baseline_probs.zip?download=1 && \
    unzip baseline_probs.zip -d /home/user/artifact/benchmarks/seventeen && \
    rm baseline_probs.zip
# Clean up the FOF benchmarks by removing comments and extra spaces
RUN mkdir -p /home/user/artifact/benchmarks/seventeen/baseline_probs/clean_FOF
RUN find /home/user/artifact/benchmarks/seventeen/baseline_probs/FOF -type f -name "*.p" | while read file; do \
        output_dir="/home/user/artifact/benchmarks/seventeen/baseline_probs/clean_FOF/$(dirname "${file#/home/user/artifact/benchmarks/seventeen/baseline_probs/FOF/}")"; \
        mkdir -p "$output_dir"; \
        output_file="$output_dir/$(basename "$file")"; \
        (sed '/^[[:blank:]]*%/d;s/%.*//' "$file" | awk '{$1=$1};1') > "$output_file"; \
    done
RUN find /home/user/artifact/benchmarks/seventeen/baseline_probs/clean_FOF -type f -name "*.p" > /home/user/artifact/seventeen_fof_all.txt && \
    sort /home/user/artifact/seventeen_fof_all.txt -o /home/user/artifact/seventeen_fof_all.txt && \
    bash -c 'shuf /home/user/artifact/seventeen_fof_all.txt --random-source=<(yes 42) -o /home/user/artifact/seventeen_fof_all.txt'
RUN find /home/user/artifact/benchmarks/seventeen/baseline_probs/SMT2 -type f -name "*.smt_in" > /home/user/artifact/seventeen_smt2_all.txt && \
    sort /home/user/artifact/seventeen_smt2_all.txt -o /home/user/artifact/seventeen_smt2_all.txt && \
    bash -c 'shuf /home/user/artifact/seventeen_smt2_all.txt --random-source=<(yes 42) -o /home/user/artifact/seventeen_smt2_all.txt'

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
# Store all paths of UNSAT SMT-LIB benchmarks into smtlib_all.txt
RUN find /home/user/artifact/benchmarks/SMT-LIB -type f -name "*.smt2" -exec grep -l "(set-info :status unsat)" {} \; > /home/user/artifact/smtlib_all.txt && \
    sort /home/user/artifact/smtlib_all.txt -o /home/user/artifact/smtlib_all.txt && \
    bash -c 'shuf /home/user/artifact/smtlib_all.txt --random-source=<(yes 42) -o /home/user/artifact/smtlib_all.txt'

# Create a virtual environment and install Python dependencies
COPY --chown=user:group requirements.txt /home/user/artifact/requirements.txt
RUN python3 -m venv /home/user/venv && \
    /home/user/venv/bin/pip install --upgrade pip && \
    /home/user/venv/bin/pip install -r /home/user/artifact/requirements.txt
# Set the virtual environment as the default Python environment
ENV VIRTUAL_ENV=/home/user/venv
ENV PATH="/home/user/venv/bin:$PATH"

# Install elan and update environment
RUN curl https://elan.lean-lang.org/elan-init.sh -sSf | sh -s -- -y --default-toolchain none
ENV PATH="/home/user/.elan/bin:$PATH"

# Install opam and initialize it without a default switch
RUN yes "/usr/local/bin" | bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)" && \
    opam init --disable-sandboxing --bare

# Clone and build Isabelle and AFP
RUN hg clone https://isabelle.in.tum.de/repos/isabelle && \
    cd isabelle && \
    hg update b87fcf474e7f
RUN isabelle/Admin/init && \
    isabelle/bin/isabelle build -b HOL
ENV PATH="/home/user/artifact/isabelle/bin:$PATH"
RUN hg clone https://foss.heptapod.net/isa-afp/afp-devel && \
    cd afp-devel && \
    hg update e2ae9549a7b0
ENV AFP="/home/user/artifact/afp-devel/thys"
RUN echo 'init_component "/home/user/artifact/afp-devel"' >> /home/user/.isabelle/etc/settings && \
    isabelle components -a
RUN isabelle afp_build -- -o document=false -o browser_info=false Abortable_Linearizable_Modules Abstract-Hoare-Logics \
    Abstract_Completeness Abstract_Soundness Berlekamp_Zassenhaus Bernoulli Bertrands_Postulate Bounded_Deducibility_Security \
    Buildings Card_Number_Partitions Category3 Cauchy CoSMeDis CoSMed Comparison_Sort_Lower_Bound Consensus_Refined CryptHOL \
    Density_Compiler Dominance_CHK Ergodic_Theory Falling_Factorial_Sum Finger-Trees First_Welfare_Theorem Fishburn_Impossibility \
    Generalized_Counting_Sort Grothendieck_Schemes Irrationality_J_Hancl IsaGeoCoq Jordan_Hoelder List_Interleaving List_Update \
    Localization_Ring Locally-Nameless-Sigma Menger MonoidalCategory Multi_Party_Computation Noninterference_CSP Pell Poincare_Disc \
    Polynomial_Interpolation Prime_Distribution_Elementary Prime_Harmonic_Series Probabilistic_Noninterference Public_Announcement_Logic \
    Regex_Equivalence Slicing Subset_Boolean_Algebras Transcendence_Series_Hancl_Rucki Triangle VeriComp
COPY --chown=user:group verit+sledgehammer.sh /home/user/artifact/verit+sledgehammer.sh
COPY --chown=user:group collect_sledgehammer_stats.py /home/user/artifact/collect_sledgehammer_stats.py

# Clone and build smtcoq and veriT
RUN opam switch create ocaml-base-compiler.4.11.1
RUN opam install -y --confirm-level=unsafe-yes num coq.8.19.2
RUN git clone https://github.com/smtcoq/smtcoq && \
    cd smtcoq/src && \
    git checkout coq-8.19 && \
    eval $(opam env) && \
    make && make install && \
    cd extraction && make
RUN curl -L -o veriT9f48a98.tar.gz https://www.lri.fr/~keller/Documents-recherche/Smtcoq/veriT9f48a98.tar.gz && \
    tar -xf veriT9f48a98.tar.gz -C /home/user/artifact && \
    rm veriT9f48a98.tar.gz
RUN cd /home/user/artifact/veriT9f48a98 && \
    ./configure && make -j"$(nproc)"
COPY --chown=user:group verit+smtcoq.sh /home/user/artifact/verit+smtcoq.sh
COPY --chown=user:group collect_smtcoq_stats.py /home/user/artifact/collect_smtcoq_stats.py

# Clone and build cvc5 and ethos
RUN git clone https://github.com/cvc5/cvc5 && \
    cd cvc5 && \
    git checkout 8aeaa1938d6cdc1dfe65d4f4414bee93c44516f7 && \
    ./configure.sh production --static --auto-download && \
    cd build && make -j"$(nproc)"
RUN cd /home/user/artifact/cvc5 && \
    contrib/get-ethos-checker
COPY --chown=user:group cvc5+ethos.sh /home/user/artifact/cvc5+ethos.sh
COPY --chown=user:group collect_ethos_stats.py /home/user/artifact/collect_ethos_stats.py

# Clone and build duper
RUN git clone https://github.com/leanprover-community/duper
COPY --chown=user:group skSorryAx.patch /home/user/artifact/duper/skSorryAx.patch
RUN cd duper && \
    git checkout v0.0.26 && \
    git apply skSorryAx.patch && \
    lake update && \
    lake build
COPY --chown=user:group duper.sh /home/user/artifact/duper.sh
COPY --chown=user:group collect_duper_stats.py /home/user/artifact/collect_duper_stats.py

# Clone and build cpc-checker
RUN git clone https://github.com/abdoo8080/lean-cpc-checker && \
    cd lean-cpc-checker && \
    git checkout c513efca48c82ec8ab3587adf5f762be28286b9a && \
    lake update && \
    lake build
COPY --chown=user:group cvc5+leansmt-compiler.sh /home/user/artifact/cvc5+leansmt-compiler.sh
COPY --chown=user:group cvc5+leansmt+compiler.sh /home/user/artifact/cvc5+leansmt+compiler.sh
COPY --chown=user:group collect_leansmt_stats.py /home/user/artifact/collect_leansmt_stats.py

# Copy the benchmark scripts
COPY --chown=user:group run_benchmarks.py /home/user/artifact/run_benchmarks.py
COPY --chown=user:group cactus.py /home/user/artifact/cactus.py
COPY --chown=user:group scatter.py /home/user/artifact/scatter.py
COPY --chown=user:group tables.py /home/user/artifact/tables.py
COPY --chown=user:group generate_figures_and_tables.sh /home/user/artifact/generate_figures_and_tables.sh
COPY --chown=user:group run_all_benchmarks.sh /home/user/artifact/run_all_benchmarks.sh

# Copy previous results
COPY --chown=user:group data/ /home/user/artifact/data/

# Set the default command to run bash
CMD ["bash"]
